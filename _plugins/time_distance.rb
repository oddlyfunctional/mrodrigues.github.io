module Jekyll
  module TimeDistance
    def time_distance(from, to = Date.today)
      from = Date.parse(from) if from.is_a?(String)
      to = Date.parse(to) if to.is_a?(String)

      months = (to.year * 12 + to.month) - (from.year * 12 + from.month)
      years = months / 12
      months %= 12

      s = ""

      if years > 0
        s += "#{years} year"

        if years > 1
          s += "s"
        end
      end

      if months > 0
        if s.length > 0
          s += " "
        end

        s += "#{months} month"

        if months > 1
          s += "s"
        end
      end

      s
    end
  end
end

Liquid::Template.register_filter(Jekyll::TimeDistance)
