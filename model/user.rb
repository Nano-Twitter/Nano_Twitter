ENV['APP_ENV'] = 'production'
require 'bcrypt'

class User
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include BCrypt

  attr_accessor :password

  field :name, type: String
  field :password_hash, type: String
  field :email, type: String
  field :bio, type: String
  field :gender, type: Integer
  field :tweets_count, type: Integer, default: 0

  index({email: 1}, {unique: true})

  has_many :tweets

  # association
  has_and_belongs_to_many :following, class_name: 'User', inverse_of: :followers, autosave: true, index: true
  has_and_belongs_to_many :followers, class_name: 'User', inverse_of: :following, index: true
  
  validates_presence_of :name
  #validates_uniqueness_of :name
  validates_presence_of :email
  #validates_uniqueness_of :email
  validates_length_of :password, minimum: 6

  before_save :encrypt_password

  def follow!(user)
    if self.following.include?(user)
      raise 'Duplicate following relationship.'
    elsif self.id != user.id
      self.following << user
      user.followers << self
    end
  end

  def unfollow!(user)
    self.following.delete(user)
    user.followers.delete(self)
  end

  def self.find_by_email(email)
    find_by(email: email)
  end

  def self.authenticate(user_email, password)
    user = find_by_email user_email
    if user.nil?
      false
    else
      user_pass = Password.new(user.password_hash)
      user_pass == password
    end
  end

  def as_json(options = {})
    attrs = super(options)
    attrs.except("password_hash")
    attrs
  end

  private

  def encrypt_password
    self.password_hash = Password.create(@password)
  end
end
