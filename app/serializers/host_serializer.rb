# frozen_string_literal: true

class HostSerializer < UserSerializer
  attributes :title

  def title
    if SiteSetting.zoom_host_title_override
      field_id = UserField.where(name: SiteSetting.zoom_host_title_override).pluck(:id).first
      return object.user_fields[field_id.to_s] || ""
    end

    object.title
  end
end
