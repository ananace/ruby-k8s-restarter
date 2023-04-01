# frozen_string_literal: true

class String
  def underscore
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end

  def camelcase
    self.split('_').map(&:capitalize).join('')
  end
end

class Numeric
  def to_duration
    s = dup
    ret = []

    if (d = s / 86400)
      ret << "#{d.to_i}d"
      s %= 86400
    end

    if (h = s / 3600)
      ret << "#{h.to_i}h"
      s %= 3600
    end

    if (m = s / 60)
      ret << "#{h.to_i}m"
      s %= 60
    end

    if self > 1
      ret << "#{s.to_i}s"
    else
      ret << "#{(s * 1000).to_i}ms"
    end

    ret.join ' '
  end
end
