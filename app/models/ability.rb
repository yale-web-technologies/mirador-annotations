class Ability
  include CanCan::Ability

  def initialize(user)
    #can :read, :all

    user ||= User.new #guest user
    #can :read, :all

    can :read, Annotation do |annotation|
      user.hasPermission user, annotation.annotation_id, "read"
    end

    can :create, Annotation do |annotation|
      p "in ability: user = #{user}"
      user.hasPermission user, annotation.annotation_id, "create"
    end

    can :update, Annotation do |annotation|
      user.hasPermission user, annotation.annotation_id, "update"
    end

    can :delete, Annotation do |annotation|
      user.hasPermission user, annotation.annotation_id, "delete"
    end

    can :read, AnnotationList do |annotationList|
      user.hasPermission user, annotationList.list_id, "read"
    end

    can :create, AnnotationList do |annotationList|
      user.hasPermission user, annotationList.list_id, "create"
    end

    can :update, AnnotationList do |annotationList|
      user.hasPermission user, annotationList.list_id, "update"
    end

    can :delete, AnnotationList do |annotationList|
      user.hasPermission user, annotationList.list_id, "delete"
    end

    can :read, AnnotationLayer do |annotationLayer|
      user.hasPermission user, annotationLayer.layer_id, "read"
    end

    can :create, AnnotationLayer do |annotationLayer|
      user.hasPermission user, annotationLayer.layer_id, "create"
    end

    can :update, AnnotationList do |annotationLayer|
      user.hasPermission user, annotationLayer.layer_id, "update"
    end

    can :delete, AnnotationList do |annotationLayer|
      user.hasPermission user, annotationLayer.layer_id, "delete"
    end

  end

end
