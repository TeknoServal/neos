require 'faraday'
require 'figaro'
require 'pry'

# Load ENV vars via Figaro
Figaro.application = Figaro::Application.new(environment: 'production', path: File.expand_path('config/application.yml', __dir__))
Figaro.load

# Gets data for near earth objects from the NASA api
class NearEarthObjects
  def self.find_neos_by_date(date)
    conn = get_connection(date)
    asteroids_list_data = conn.get('/neo/rest/v1/feed')

    parsed_asteroids_data = parse_asteroids_data(asteroids_list_data, date)

    {
      astroid_list: format_data(parsed_asteroids_data),
      biggest_astroid: largest_diameter(parsed_asteroids_data),
      total_number_of_astroids: parsed_asteroids_data.count
    }
  end

  def self.get_connection(date)
    Faraday.new(
      url: 'https://api.nasa.gov',
      params: { start_date: date, end_date: date, api_key: ENV['nasa_api_key'] }
    )
  end

  def self.parse_asteroids_data(data, date)
    JSON.parse(data.body, symbolize_names: true)[:near_earth_objects][:"#{date}"]
  end

  def self.largest_diameter(data)
    data.map do |astroid|
      astroid[:estimated_diameter][:feet][:estimated_diameter_max].to_i
    end.max
  end

  def self.format_data(data)
    data.map do |astroid|
      {
        name: astroid[:name],
        diameter: "#{astroid[:estimated_diameter][:feet][:estimated_diameter_max].to_i} ft",
        miss_distance: "#{astroid[:close_approach_data][0][:miss_distance][:miles].to_i} miles"
      }
    end
  end
end
