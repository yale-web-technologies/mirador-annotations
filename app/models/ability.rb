class Ability
  include CanCan::Ability

  def initialize(user)
    #can :read, :all

    user ||= User.new #guest user
    can :create, :all


    can :read, Annotation do |annotation|
      user.hasPermission user, annotation.annotation_id, "read"
    end

    #can :create, Annotation do |annotation|
    #  user.hasPermission user, annotation.annotation_id, "create"
    #end

    can :update, Annotation do |annotation|
      user.hasPermission user, annotation.annotation_id, "update"
    end

    can :delete, Annotation do |annotation|
      user.hasPermission user, annotation.annotation_id, "delete"
    end
  end

end