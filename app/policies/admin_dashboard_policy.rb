class AdminDashboardPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def owner_only?
    user.owner?
  end
end
