class LotteryMigration
  def self.update_selections
    p "Updating Lottery selections..."
    Lottery.all.each {|ticket| update_selection(ticket)}
    p "Done."
  end

  def self.update_selection(ticket)
    new_selections = []
    ticket[:selection].each do |prod_key|
      
      prod = Product.find_by_key(prod_key)
      new_selections << {language: prod[:language], prod_key: prod[:prod_key]} 
    end

    unless new_selections.empty?
      ticket[:selection] = new_selections
      ticket.save
    end
  end
end
