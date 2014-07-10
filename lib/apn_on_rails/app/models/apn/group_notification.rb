# encoding: utf-8
class APN::GroupNotification < APN::Base
  include ::ActionView::Helpers::TextHelper
  extend ::ActionView::Helpers::TextHelper
  serialize :custom_properties

  belongs_to :group, :class_name => 'APN::Group'
  has_one :app, :class_name => 'APN::App', :through => :group
  has_many :device_groupings, :through => :group

  validates_presence_of :group_id

  def devices
    self.group.devices
  end

  # Stores the text alert message you want to send to the device.
  # 
  # If the message is over 150 characters long it will get truncated
  # to 150 characters with a <tt>...</tt>
  def alert=(message)
    if !message.blank? && message.size > 150
      message = truncate(message, :length => 150)
    end
    write_attribute('alert', message)
  end

  # Creates a Hash that will be the payload of an APN.
  # 
  # Example:
  #   apn = APN::GroupNotification.new
  #   apn.badge = 5
  #   apn.sound = 'my_sound.aiff'
  #   apn.alert = 'Hello!'
  #   apn.apple_hash # => {"aps" => {"badge" => 5, "sound" => "my_sound.aiff", "alert" => "Hello!"}}
  #
  # Example 2: 
  #   apn = APN::GroupNotification.new
  #   apn.badge = 0
  #   apn.sound = true
  #   apn.custom_properties = {"typ" => 1}
  #   apn.apple_hash # => {"aps" => {"badge" => 0, "sound" => 1.aiff},"typ" => "1"}
  def apple_hash
    result = {}
    result['aps'] = {}
    result['aps']['alert'] = self.alert if self.alert
    result['aps']['badge'] = self.badge.to_i if self.badge
    if self.sound
      result['aps']['sound'] = self.sound if self.sound.is_a?(String) && self.sound.strip.present?
      result['aps']['sound'] = "1.aiff" if self.sound.is_a?(TrueClass)
    end
    if self.custom_properties
      self.custom_properties.each do |key, value|
        result["#{key}"] = "#{value}"
      end
    end
    result
  end

  def payload
    multi_json_dump(apple_hash)
  end

  def payload_size
    payload.bytesize
  end

  # Creates the JSON string required for an APN message.
  # 
  # Example:
  #   apn = APN::Notification.new
  #   apn.badge = 5
  #   apn.sound = 'my_sound.aiff'
  #   apn.alert = 'Hello!'
  #   apn.to_apple_json # => '{"aps":{"badge":5,"sound":"my_sound.aiff","alert":"Hello!"}}'
  def to_apple_json
    self.apple_hash.to_json
  end

  # Creates the binary message needed to send to Apple.
  #def message_for_sending(device)
  #  json = self.to_apple_json.gsub(/\\u([0-9a-z]{4})/) { |s| [$1.to_i(16)].pack("U") } # This will create non encoded string. Otherwise the string is encoded from utf8 to ascii with unicode representation (i.e. \\u05d2)
  #  message = "\0\0 #{device.to_hexa}\0".force_encoding("UTF-8") + "#{json.length.chr}#{json}".force_encoding("UTF-8")
  #  raise APN::Errors::ExceededMessageSizeError.new(message) if message.size.to_i > 256
  #  message
  #end

  # This method conforms to the enhanced binary format.
  # http://developer.apple.com/library/ios/#documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CommunicatingWIthAPS/CommunicatingWIthAPS.html#//apple_ref/doc/uid/TP40008194-CH101-SW4
  def message_for_sending(device)
    message = [1, device.id, 1.day.to_i, 0, 32, device.token, payload_size, payload].pack("cNNccH*na*")
    raise APN::Errors::ExceededMessageSizeError.new(message) if message.size.to_i > 256
    message
  end


  private

  def multi_json_load(string, options = {})
    # Calling load on multi_json less than v1.3.0 attempts to load a file from disk. Check the version explicitly.
    if Gem.loaded_specs['multi_json'].version >= Gem::Version.create('1.3.0')
      MultiJson.load(string, options)
    else
      MultiJson.decode(string, options)
    end
  end

  def multi_json_dump(string, options = {})
    MultiJson.respond_to?(:dump) ? MultiJson.dump(string, options) : MultiJson.encode(string, options)
  end

end # APN::Notification