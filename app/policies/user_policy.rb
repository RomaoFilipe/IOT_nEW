class UserPolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def show?
    user.admin? || user.manager?
  end

  def create?
    user.admin?
  end

  def update?
    user.admin? || (user.manager? && record.role == "viewer")
  end

  def destroy?
    user.admin?
  end

  def admin_dashboard?
    user.admin?
  end

  def entrar_como?
    user.admin? && user != record
  end

  def retornar_como_admin?
    user.admin?
  end
end
