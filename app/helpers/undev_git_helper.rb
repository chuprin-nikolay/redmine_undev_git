module UndevGitHelper
  def changeset_branches(changeset, max_branches = nil)
    return '' unless changeset.repository.is_a? Repository::UndevGit
    max = max_branches.to_i
    brs = max > 0 ? changeset.branches[0...max] : changeset.branches
    links = brs.map do |branch|
      link_to_branch(branch, changeset.repository, changeset.scmid)
    end
    links << '...' if changeset.branches.length > brs.length
    "(#{links.join('; ')})".html_safe
  end

  def link_to_repository(repository)
    repository = repository.repository if repository.is_a?(Project)
    link_to repository.name,
            { controller:      'repositories',
                action:        'show',
                id:            repository.project,
                repository_id: repository.identifier_param,
                rev:           nil,
                path:          nil },
            target: 'repository'
  end

  def link_to_branch(branch, repository, revision = nil)
    link_to(h(branch), url_for(
            controller:     'repositories',
            action:         'show',
            id:             repository.project,
            repository_id:  repository.identifier_param.present? ?
                                repository.identifier_param : nil,
            path:           nil,
            params:         {
                branch: branch,
                rev:    revision
            },
            trailing_slash: false)
    )
  end

  def link_to_revision_wb(revision, repository, &block)
    if repository.is_a?(Project)
      repository = repository.repository
    end
    rev = revision.respond_to?(:identifier) ? revision.identifier : revision
    link_to(
        {
            controller:    'repositories',
            action:        'revision',
            id:            repository.project,
            repository_id: repository.identifier_param,
            rev:           rev
        },
        target: l(:label_revision_id, format_revision(revision)),
        &block
    )
  end

  def link_to_remote_revision(revision)
    [
        link_to("#{revision.short_sha}", revision.uri, target: '_blank'),
        links_to_remote_branches(revision),
        link_to("#{revision.repo.path_to_repo}", revision.repo.uri, target: '_blank')
    ].join(' ').html_safe
  end

  def links_to_remote_branches(revision)
    max_refs = RedmineUndevGit.max_branches_in_assoc
    links = revision.refs.limit(max_refs).map do |ref|
      link_to(ref.name, ref.uri, target: '_blank')
    end
    links << '...' if revision.refs.count > max_refs
    "(#{links.join('; ')})".html_safe
  end

  def undev_git_field_tags(form, repository)
    [
        undev_git_url_tag(form, repository),
        undev_git_extra_report_last_commit_tag(form, repository),
        undev_git_use_init_hooks_tag(form, repository),
        undev_git_use_init_refs_tag(form, repository),
        undev_git_fetch_by_web_hook_tag(form, repository)
    ].compact.join('<br />').html_safe
  end

  private

  def undev_git_url_tag(form, repository)
    content_tag('p', form.text_field(
            :url, label: l(:field_path_to_repository),
            size: 60, required: true,
            disabled: repository.persisted?))
  end

  def undev_git_extra_report_last_commit_tag(form, repository)
    content_tag('p', form.check_box(
            :extra_report_last_commit,
            label: l(:label_git_report_last_commit)))
  end

  def undev_git_use_init_hooks_tag(form, repository)
    content_tag('p', form.check_box(
            :use_init_hooks,
            disabled: repository.persisted?,
            label: :field_use_init_hooks))
  end

  def undev_git_use_init_refs_tag(form, repository)
    content_tag('p', form.check_box(
            :use_init_refs,
            disabled: repository.persisted?,
            label: :field_use_init_refs))
  end

  def undev_git_fetch_by_web_hook_tag(form, repository)
    content_tag 'p',
        form.check_box(:fetch_by_web_hook,
            disabled: RedmineUndevGit.fetch_by_web_hook?,
            label: :field_fetch_by_web_hook) +
            render(partial: 'settings/web_hooks_description')
  end
end
