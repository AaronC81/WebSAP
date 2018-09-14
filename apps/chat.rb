# A chat app.
class Chat
  def self.name
    'chat'
  end

  def self.initial_state
    { messages: [] }
  end

  def self.transform(state, action, options)
    case action
    when 'send_message'
      state[:messages] << options['message']
      true
    when 'note'
      state[hlkey(options)] ||= { notes: [] }
      state[hlkey(options)][:notes] << options['note']

      p state
    else
      false
    end
  end
end
