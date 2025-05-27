module SensorsHelper
  def battery_icon(level)
    level = level.to_i

    color = if level >= 80
      "text-green-600"
    elsif level >= 40
      "text-yellow-500"
    else
      "text-red-500"
    end

    raw <<~SVG
      <svg class="w-4 h-4 #{color}" fill="currentColor" viewBox="0 0 20 20">
        <path d="M3 6a2 2 0 012-2h9a2 2 0 012 2v1h1a1 1 0 011 1v4a1 1 0 01-1 1h-1v1a2 2 0 01-2 2H5a2 2 0 01-2-2V6z" />
      </svg>
    SVG
  end

  def signal_icon(level)
    level = level.to_i

    color = if level >= 80
      "text-green-600"
    elsif level >= 40
      "text-yellow-500"
    else
      "text-red-500"
    end

    raw <<~SVG
      <svg class="w-4 h-4 #{color}" fill="currentColor" viewBox="0 0 20 20">
        <path d="M2 14a1 1 0 100 2 1 1 0 000-2zm4-3a1 1 0 100 2 1 1 0 000-2zm4-3a1 1 0 100 2 1 1 0 000-2zm4-3a1 1 0 100 2 1 1 0 000-2z" />
      </svg>
    SVG
  end
end
