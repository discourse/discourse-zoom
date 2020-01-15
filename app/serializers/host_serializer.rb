# frozen_string_literal: true

class HostSerializer < BasicUserSerializer
  attributes :title, :avatar_template

  def title
    if SiteSetting.zoom_host_title_override
      field_id = UserField.where(name: SiteSetting.zoom_host_title_override).pluck(:id).first
      return object.user_fields[field_id.to_s] || ""
    end

    object.title
  end

  def avatar_template
    User.avatar_template(object.username, object.uploaded_avatar_id)
  end

  def include_avatar_template?
    true
  end
end
