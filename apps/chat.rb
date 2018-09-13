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
    when 'send message'
      state[:messages] << options['message']
      true
    when 'note'
      state[:"$#{options['key']}"] ||= { notes: [] }
      state[:"$#{options['key']}"][:notes] << options['note']

      p state
    else
      false
    end
  end
end
