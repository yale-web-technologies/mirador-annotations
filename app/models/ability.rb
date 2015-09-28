class Ability
  include CanCan::Ability

  def initialize(user)
    can :read, :all

    user ||= User.new #guest user
    can :create, :all

    can :update, Annotation do |annotation|
      user.webacls.where(resource_id: annotation.annotation_id, acl_mode: "update").first
    end

    can :delete, Annotation do |annotation|
      user.webacls.where(resource_id: annotation.annotation_id, acl_mode: "delete").first
    end
  end

end