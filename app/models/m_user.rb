class MUser < ApplicationRecord
  has_many :t_group_messages, dependent: :destroy
  has_many :t_direct_messages, dependent: :destroy
  has_many :t_direct_threads, dependent: :destroy

  has_many :active_relationships, class_name:  "TUserWorkspace",
                                  foreign_key: "userid",
                                  dependent:   :destroy

  has_many :m_users, through: :active_relationships, source: :m_user

  has_many :active_relationships, class_name:  "TUserChannels",
                                  foreign_key: "userid",
                                  dependent:   :destroy

  has_many :m_users, through: :active_relationships, source: :m_user

  has_many :active_relationships, class_name:  "TGroupMentionMsgs",
                                  foreign_key: "userid",
                                  dependent:   :destroy

  has_many :m_users, through: :active_relationships, source: :m_user

  has_many :active_relationships, class_name:  "TGroupMentionMsgs",
                                  foreign_key: "userid",
                                  dependent:   :destroy

  has_many :m_users, through: :active_relationships, source: :m_user

  has_many :active_relationships, class_name:  "TGroupStarMsgs",
                                  foreign_key: "userid",
                                  dependent:   :destroy

  has_many :m_users, through: :active_relationships, source: :m_user

  has_many :active_relationships, class_name:  "TGroupMentionThread",
                                  foreign_key: "userid",
                                  dependent:   :destroy

  has_many :m_users, through: :active_relationships, source: :m_user

  has_many :active_relationships, class_name:  "TGroupStarThread",
  foreign_key: "userid",
  dependent:   :destroy

  has_many :m_users, through: :active_relationships, source: :m_user

  has_one :m_users_profile_image, dependent: :destroy

  before_save   :downcase_email
  validates :remember_digest,  presence: true, length: { maximum: 50 }, uniqueness: { case_sensitive: false }, on: :create
  validates :profile_image,  presence: true, length: { maximum: 50 }, on: :create
  validates :name,  presence: true, length: { maximum: 50 }, uniqueness: { case_sensitive: false }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
                  format: { with: VALID_EMAIL_REGEX }
  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

  private

  # Converts email to all lower-case.
  def downcase_email
    self.email = email.downcase
  end
end

