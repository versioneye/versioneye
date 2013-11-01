class LotteryMigration
  def self.update_selections
    p "Updating Lottery selections..."
    Lottery.where(:ticket.in => [nil, false]).each {|ticket| update_selection(ticket)}
    total = Lottery.all.count
    success = Lottery.where(migrated: true).count
    p "Done. Success: #{success}/#{total}. Failed: #{total - success}"
  end

  def self.update_selection(ticket)
    new_selections = []
    ticket[:selection].each do |selection|

      if selection.is_a?(Hash)
        prod_key =  selection["prod_key"]
      end

      if selection.is_a?(String)
        prod_key = selection
      end

      prod_key = Product.decode_prod_key(prod_key)
      prod     = Product.find_by_key(prod_key)
      unless prod.nil?
        new_selections << {language: prod[:language], prod_key: prod[:prod_key]}
      else
        p "Error: Can't migrate ticket #{ticket[:_id].to_s} . Didn't find product for: #{prod_key}"

        ticket[:migrated] = false
        ticket.save
        return
      end
    end

    unless new_selections.empty?
      ticket[:selection] = new_selections
      ticket[:migrated] = true
      ticket.save
    end
  end
end
