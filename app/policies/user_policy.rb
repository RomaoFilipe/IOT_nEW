class UserPolicy < ApplicationPolicy
  def index?
    user.owner? || user.admin?
  end

  def show?
    user.owner? || user.admin? || user.manager?
  end

  def create?
    user.owner? || user.admin?
  end

  def update?
    return true if user.owner?
    user.admin? || (user.manager? && record.role == "viewer")
  end

  def destroy?
    user.owner? || user.admin?
  end

  def admin_dashboard?
    user.owner? || user.admin?
  end

  # 👥 Simular utilizador
  def entrar_como?
    user.owner? && user != record
  end

  # 🔙 Voltar ao modo Owner
  def retornar_como_admin?
    user.owner?
  end
end
