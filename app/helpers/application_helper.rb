module ApplicationHelper
  def format_time(seconds)
    minutes = (seconds / 60).to_i
    hours = (minutes / 60).to_i
    remaining_minutes = minutes % 60
    remaining_seconds = seconds % 60
    "#{hours}h #{remaining_minutes}m #{remaining_seconds}s"
  end

  def safe_path(*candidates)
    meth = candidates.find { |m| respond_to?(m) }
    meth ? public_send(meth) : root_path
  end

  # Atalho para abrir a página de "Campos" já no separador Mapa
  # Uso: fields_map_path => /fields?view=map
  def fields_map_path
    base = respond_to?(:fields_path) ? fields_path : root_path
    uri  = URI.parse(base.to_s)
    params = Rack::Utils.parse_nested_query(uri.query).merge('view' => 'map')
    uri.query = params.to_query
    uri.to_s
  end
end
