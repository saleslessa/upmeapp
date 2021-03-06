class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  enum user_type: [:aluno, :professor, :empresa]
  enum tipo_pessoa: [:fisica, :juridica]
  has_many :user_area_de_interesse


  def update_areas_de_interesse(ar_nome_areas)
    user_area_de_interesse.destroy_all
    areas_selecionadas = AreaDeInteresse.where(name: ar_nome_areas)
    areas_selecionadas.each do |area_de_interesse|
      user_area_de_interesse.create(area_de_interesse_id: area_de_interesse.id)
    end
    save
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def my_projects
    Project.where(id: ProjectUser.where(user_id: id).pluck(:project_id)).where(deleted: false)
  end

  def my_filed_projects
    Project.where(id: ProjectUser.where(user_id: id).pluck(:project_id)).where(deleted: true)
  end

  def my_invitations
    ProjectInvitation.where(user_to_id: id)
  end

  def profile_is_complete?
    return false if city.blank?
    if aluno?
      return false if universidade.blank? or semestre.blank?
    end

    if empresa?
      return false if nome_empresa.blank?
    end

    true
  end

  def billing_data_is_complete?
    return false if tipo_pessoa.blank? or cep.blank? or endereco.blank? or numero.blank? or uf.blank? or cidade.blank? or cpf.blank? or telefone.blank?
    true
  end

  def available_projects
    if empresa?
      Project.available_empresa_projects
    else
      Project.available_aluno_projects
    end
  end

  def can_timeline_comment?(project, step)
    project.has_user(self)
  end

  def can_finish_step?(project, step)
    project.has_user(self) and project.has_step(step) and project.client_id == self.id and !step.entregue?
  end

  def can_edit_step_entrega?(project, step)
    true if professor? and project.has_user(self) and project.has_step(step) and !step.entregue?
  end

  def user_label
    return 'aluno(a)' if aluno?
    return 'professor(a)' if professor?
    'empresa'
  end

end
