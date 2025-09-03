module UiHelper
  def badge_class_for_farm_type(type)
    case type
    when "agriculture"      then "bg-emerald-50 text-emerald-700 ring-1 ring-emerald-200"
    when "aquaculture_sea"  then "bg-blue-50 text-blue-700 ring-1 ring-blue-200"
    when "aquaculture_tank" then "bg-cyan-50 text-cyan-700 ring-1 ring-cyan-200"
    else                         "bg-slate-100 text-slate-700 ring-1 ring-slate-200"
    end
  end

  def chip_class_for_farm_type(type)
    case type
    when "agriculture"      then "bg-green-100 text-green-700"
    when "aquaculture_sea"  then "bg-cyan-100 text-cyan-700"
    when "aquaculture_tank" then "bg-blue-100 text-blue-700"
    else                         "bg-slate-100 text-slate-700"
    end
  end

  def chip_class_for_role(role)
    case role
    when "admin"      then "bg-yellow-100 text-yellow-800"
    when "manager"    then "bg-emerald-100 text-emerald-700"
    when "technician" then "bg-violet-100 text-violet-700"
    when "viewer"     then "bg-slate-100 text-slate-600"
    else                   "bg-rose-100 text-rose-700"
    end
  end
end
