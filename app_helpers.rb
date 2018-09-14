module AppHelpers
  # Calculates the locked state hash key from the key supplied in options.
  def hlkey(options)
    :"$#{options['key']}"
  end
end