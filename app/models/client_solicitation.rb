class ClientSolicitation < ApplicationRecord
  belongs_to :project
  belongs_to :user

  validate :solicitation_already_exists
  validate :only_empresa

  def self.new_solicitation(current_user, project, message)
    ClientSolicitation.new({
      user_id: current_user.id,
      project_id: project.id,
      message: message
    })
  end

  def accept(current_user)
    if project.user_id == current_user.id
      project.add_user(self.user)
      project.start
      project.update_attribute :client_id, self.user_id
      ClientSolicitationMailer.accept(user, project.user, project).deliver_later
      self.destroy
    end
  end

  def refuse(current_user)
    if project.user_id == current_user.id
      ClientSolicitationMailer.refuse(user, project.user, project).deliver_later
      self.destroy
    end
  end

  def solicitation_already_exists
    if ClientSolicitation.where(project_id: project_id).where(user_id: user_id).size > 0
      errors.add(:invitation_already_exists, 'Convite já enviado.')
    end
  end

  def self.solicitation_exists(project, user)
    ClientSolicitation.where(project_id: project.id).where(user_id: user.id).size > 0
  end

  def only_empresa
    unless user.empresa?
      errors.add(:not_empresa, 'Apenas empresas podem pode participar de um projeto de aluno ou professor')
    end
  end

end
