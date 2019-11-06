module ControlPanelHelper
  def em_role_privileges_to_list(privileges)
    return 'Sin permisos asignados' if privileges == '{}'

    privileges = JSON.parse(privileges, symbolize_names: true)
    privileges.map { |p| available_privileges[p[0]] }.join("<br>\n")
  end

  def em_role_privileges_to_params(privileges)
    privileges = JSON.parse(privileges, symbolize_names: true)
    privileges.each_with_object({}) do |privilege, new_params|
      new_params[privilege[0]] = 'on' if privilege[1] == true
    end
  end

  def em_role_privileges_to_hash(privileges)
    JSON.parse(privileges, symbolize_names: true)
  end

  def available_privileges
    {
      absence_new: 'Puede cargar/modificar ausencias',
      absence_license_new: 'Puede cargar partes médicos',
      absence_assign: 'Puede asignar suplentes',
      absence_unassign: 'Puede remover suplentes',
      absence_cancel: 'Puede eliminar ausencias',

      client_new: 'Puede crear/modificar clientes',
      client_logo: 'Puede modificar logo de clientes',
      client_archive: 'Puede archivar clientes',
      client_unarchive: 'Puede reactivar clientes',

      location_new: 'Puede crear/modificar estaciones',
      location_contract_edit: 'Puede modificar contratos',
      location_archive: 'Puede archivar estaciones',
      location_unarchive: 'Puede reactivar estaciones',

      shift_new: 'Puede crear/modificar turnos',
      shift_assign: 'Puede asignar empleados a turnos',
      shift_unassign: 'Puede remover empleados de turnos',
      shift_delete: 'Puede archivar/eliminar turnos',

      shift_backup_new: 'Puede crear/modificar refuerzos',
      shift_backup_assign: 'Puede asignar empleados a refuerzos',
      shift_backup_unassign: 'Puede remover empleados de refuerzos',
      shift_backup_delete: 'Puede eliminar refuerzos',

      employee_new: 'Puede crear/modificar empleados',
      employee_avatar: 'Puede modificar avatar de empleados',
      employee_availability: 'Puede modificar disponibilidad de empleados',
      employee_archive: 'Puede archivar empleados',
      employee_unarchive: 'Puede reactivar empleados',

      late_arrival_new: 'Puede cargar llegadas tarde',
      late_arrival_delete: 'Puede eliminar llegadas tarde',

      overtime_new: 'Puede horas adicionales a empleados',
      overtime_delete: 'Puede eliminar horas adicionales de empleados',

      employee_file_new: 'Puede subir archivos al fichedo de empleado',
      employee_file_delete: 'Puede borrar archivos del fichedo de empleado',

      holiday_new: 'Puede cargar feriados',
      holiday_delete: 'Puede eliminar feriados',

      document_new: 'Puede crear/modificar documentos',
      document_delete: 'Puede eliminar documentos',
      document_employee: 'Puede imprimir documentos con empleados',

      job_types_new: 'Puede crear tipos de trabajo',
      job_types_delete: 'Puede eliminar tipos de trabajo',

      file_types_new: 'Puede crear tipos de archivos',
      file_types_delete: 'Puede eliminar tipos de archivos',

      users_new: 'Puede crear usuarios',
      users_password: 'Puede modificar contraseña de usuarios',
      users_role: 'Puede modificar el rol de usuarios',
      users_delete: 'Puede eliminar usuarios',

      roles_new: 'Puede crear/modificar roles de usuario',
      roles_delete: 'Puede remover roles de usuario'
    }
  end
end
