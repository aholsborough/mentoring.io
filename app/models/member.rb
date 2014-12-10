class Member < ActiveRecord::Base
  require 'digest/md5'
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable, :omniauth_providers => [:github]

  cattr_reader :expertise_levels

  @@expertise_levels = {
    1 => 'No programming knowledge',
    2 => "I'm familiar with html and css",
    3 => 'I know some basic programming',
    4 => 'Junior developer',
    5 => 'Mid-level developer',
    6 => 'Senior developer'
  }

  # ASSOCIATIONS
  has_many :member_skills
  has_many :skills, through: :member_skills
  accepts_nested_attributes_for :member_skills, :allow_destroy => true
  has_many :classifieds
  has_many :member_interests
  has_many :interests, through: :member_interests
  accepts_nested_attributes_for :member_interests, :allow_destroy => true
  has_many :messages

  has_many :added_interests, class_name: :Interest, foreign_key: "added_by"
  has_one :verifier

  #SCOPES

  scope :mentors, -> {where(:mentor => true)}
  scope :with_complete_profile, -> {where(complete: true)}

  #CALLBACKS
  before_save :set_complete

  def self.from_omniauth(auth, mentor=false)
    if member = Member.find_by_email(auth.info.email)
      member.provider = auth.provider
      member.uid = auth.uid
    else
      member = Member.where(provider: auth.provider, uid: auth.uid).first
      member = Member.new if member.nil?
      member.provider = auth.provider
      member.uid = auth.uid
      member.email = auth.info.email
      member.password = Devise.friendly_token[0,20]
      member.mentor = mentor
      member.save
    end
    member
  end

  def verified?
    verifier && verifier.verified_at.present?
  end

  # VALIDATION
  def validate
    validates_presence [:username, :email, :full_name]
  end

  def profile_complete?
    username.present? && about.present? && location.present?
  end

  def gravatar_image(size = 100)
    hash = Digest::MD5.hexdigest(email)
    "http://www.gravatar.com/avatar/#{hash}?s=#{size}"
  end

  def classified_messages
    classifieds.map(&:messages).flatten
  end

  private

  def set_complete
    self.complete = profile_complete?
    return
  end
end
