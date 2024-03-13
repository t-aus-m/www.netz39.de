require 'icalendar'
require 'redcarpet'
require 'redcarpet/render_strip' 

module Jekyll
  class IcsGenerator < Generator
    safe true
    priority :low

    def generate(site)
      events = site.collections['events'].docs
      default_organizer = "Netz39 Team <kontakt@netz39.de>"
      default_location = "Netz39 e.V., Leibnizstraße 32, 39104 Magdeburg"

      cal = Icalendar::Calendar.new

      events.each do |event|
        title = event.data['title']
        date = event.data.dig('event', 'date') || event.data['event_date']
        duration = event.data.dig('event', 'duration')
        organizer = event.data.dig('event', 'organizer') || default_organizer
        location = event.data.dig('event', 'location') || default_location

        # Remove image URLs from description
        content = event.content
        content.gsub!(/\!\[.*?\]\((.*?)\)/, '')

        # Render Markdown content to plain text
        markdown_parser = Redcarpet::Markdown.new(Redcarpet::Render::StripDown)
        description = markdown_parser.render(content)

        # Create new event and set its properties
        ical_event = Icalendar::Event.new
        if duration
          ical_event.dtstart = date
          ical_event.dtend = date + duration.to_i * 60
        else
          ical_event.dtstart = Icalendar::Values::Date.new(date)
          ical_event.dtend = Icalendar::Values::Date.new(date)
        end
        ical_event.summary = title
        ical_event.description = description
        ical_event.organizer = organizer
        ical_event.location = location
        cal.add_event(ical_event)
      end
      site.pages << IcalPage.new(site, site.source, 'feed/eo-events', "events.ics", cal)

      puts "Generated events.ics page from #{events.length} events"
    end
  end

  class IcalPage < Page
    def initialize(site, base, dir, name, calendar)
      @site = site
      @base = base
      @dir  = dir
      @name = name

      self.process(name)
      self.content = calendar.to_ical
      self.data = {
        'layout' => nil
      }
    end
  end
end
