module Concerns::DeviseOverrides
  extend ActiveSupport::Concern

  included do
    include InstanceMethods
  end

  module InstanceMethods
    def after_sign_up_path_for(resource)
      new_member_profile_path
    end

    def after_sign_in_path_for(resource)
      unless resource.profile_complete?
        flash[:alert] = "Create your profile to complete your registration"
        return new_member_profile_path
      end

      if resource.mentor
        new_member_member_skill_path(resource)
      else
        new_member_classified_path(resource)
      end
    end
  end
end
