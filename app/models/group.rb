class Group < ActiveRecord::Base
  #has_and_belongs_to_many :webacls, foreign_key: :group_id, primary_key: :group_id
  has_many :webacls, foreign_key: :group_id, primary_key: :group_id
  has_and_belongs_to_many :users, foreign_key: :group_id, primary_key: :group_id
  #has_many :users, foreign_key: "group_id"

  attr_accessible :group_id, :group_description
end
