# frozen_string_literal: true

class String
  # Converts a CamelCaseString into an underscore_string
  def underscore
    gsub(/::/, '/')
      .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      .gsub(/([a-z\d])([A-Z])/, '\1_\2')
      .tr('-', '_')
      .downcase
  end

  # Converts an underscore_string into a CamelCaseString
  def camelcase
    if include?('/')
      split('/').map(&:camelcase).join('::')
    else
      split('_').map(&:capitalize).join
    end
  end
end

class Numeric
  # Converts a duration in seconds into a duration string
  def to_duration
    s = dup
    ret = []

    if (d = s / 86_400)
      ret << "#{d.to_i}d"
      s %= 86_400
    end

    if (h = s / 3_600)
      ret << "#{h.to_i}h"
      s %= 3_600
    end

    if (m = s / 60)
      ret << "#{m.to_i}m"
      s %= 60
    end

    ret << if self > 1
             if self > 5
               "#{s.to_i}s"
             else
               "#{s.round(1)}s"
             end
           else
             "#{(s * 1000).to_i}ms"
           end

    ret.join ' '
  end
end
