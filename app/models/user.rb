class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  before_save :delete_avatar, if: -> { remove_avatar == '1' && !avatar_updated_at_changed? }
  attr_accessor :login
  attr_accessor :remove_avatar

  # Add Avatar Stuff for Paperclip
  has_attached_file :avatar, styles: { medium: "300x300>", thumb: "140x140#" }, default_url: "/images/:style/missing.png"
  validates_attachment_content_type :avatar, content_type: /\Aimage\/.*\Z/

  validate :validate_username
  # Only allow letter, number, underscore and punctuation.
  validates :username, format: {message: "can only contain letters, numbers, underscores or dashes.", with: /\A[A-Za-z0-9\-\_]+\z/ }, presence: true

  has_many :posts
  has_many :comments
  has_many :likes

  def likes?(post)
    post.likes.where(user_id: id).any?
  end

  private
   def delete_avatar
     self.avatar = nil
   end

   def validate_username
     if User.where(email: username).exists?
       errors.add(:username, :invalid)
     end
   end

   # Override find_for_database_authentication
     # If you're not using PostgreSQL you may run into some problems here
     def self.find_for_database_authentication(warden_conditions)
         conditions = warden_conditions.dup
         if login = conditions.delete(:login)
           where(conditions.to_hash).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
         else
           where(conditions.to_hash).first
         end
     end
end
