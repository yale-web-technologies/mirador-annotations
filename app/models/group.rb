class Group < ActiveRecord::Base
  #has_and_belongs_to_many :webacls, foreign_key: :group_id, primary_key: :group_id
  has_many :webacls, foreign_key: :group_id, primary_key: :group_id, :validate =>false, :dependent =>:delete_all
  #has_and_belongs_to_many :users, foreign_key: :group_id, primary_key: :group_id, :validate =>false, :dependent =>:restrict_with_error
  has_many :users, foreign_key: "group_id"

  attr_accessible :group_id, :group_description
end
