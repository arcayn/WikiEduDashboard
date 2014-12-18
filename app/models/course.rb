class Course < ActiveRecord::Base
  has_and_belongs_to_many :users
  has_many :revisions, through: :users
  has_many :articles, through: :revisions
  # has_many :assignments
  # has_many :assigned_articles, -> { uniq }, through: :assignments, :class_name => "Article"

  # Instance methods
  def update_participants(all_participants=[])
    if all_participants.blank?
      all_participants = Wiki.get_students_in_course self.id
    end
    unless all_participants.blank?
      all_participants.each do |p|
        user = User.find_or_create_by(wiki_id: p)
        unless user.courses.any? {|course| course.id == self.id }
          user.courses << self
        end
        user.save
      end
    end
  end

  def update(data={})
    if data.blank?
      data = Wiki.get_course_info self.id
    end
    # Assumes 'School/Class (Term)' format
    course_info = data["name"].split(/(.*)\/(.*)\s\(([^\)]+)/)
    self.school = course_info[1]
    self.title = course_info[2]
    self.term = course_info[3]
    self.start = data["start"].to_date
    self.end = data["end"].to_date
    if !data["students"].blank? && data["students"]["username"].kind_of?(Array)
      self.update_participants data["students"]["username"]
    end
    self.save
  end

  # Class methods
  def self.update_all_courses
    courses = Utils.chunk_requests(CourseList.all) {|block| Wiki.get_course_info block}
    courses.each do |c|
      course = Course.find_or_create_by(id: c["id"])
      course.update c
    end
  end
end
