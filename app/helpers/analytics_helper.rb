module AnalyticsHelper
  def last_val(arr)
    return nil if arr.blank?
    arr.compact.last
  end

  def sum_vals(enum)
    return 0 if enum.blank?
    if enum.is_a?(Hash)
      enum.values.compact.map(&:to_f).sum
    else
      enum.compact.map(&:to_f).sum
    end
  end

  def money_eur(v)
    return "—" if v.nil?
    number_to_currency(v.to_f, unit: "€", separator: ",", delimiter: ".", format: "%u%n")
  end

  def pct(v)
    return "—" if v.nil?
    "#{v.to_f.round(1)}%"
  end
def safe_time(value)
    case value
    when Time, ActiveSupport::TimeWithZone
      value
    else
      Time.zone.parse(value.to_s)
    end
  rescue
    Time.current
  end
  # score simplista (0–100) com base em pH (ideal ~7.5) e turbidez (baixo é melhor)
  def water_quality_score(ph: nil, turbidity: nil)
    return nil if ph.nil? && turbidity.nil?
    score_ph =
      if ph.nil? then 50
      else
        diff = (ph.to_f - 7.5).abs
        [[100 - diff * 18.0, 0].max, 100].min # 0.5 fora → -9%, 1 fora → -18%
      end
    score_turb =
      if turbidity.nil? then 70
      else
        # 0–5 NTU excelente, 10 aceitável, >20 mau
        case turbidity.to_f
        when 0..5   then 95
        when 5..10  then 85
        when 10..20 then 70
        else 50
        end
      end
    ((score_ph + score_turb) / 2.0).round
  end

  def to_json_safe(obj)
    (obj || {}).to_json
  end

  def month_series_hash_to_array(hsh, meses_pt)
    # recebe {"Jan"=>10,"Fev"=>20...} -> [10,20,...] pela ordem de MESES_PT
    meses_pt.map { |m| hsh.to_h[m].to_f }
  end
end
