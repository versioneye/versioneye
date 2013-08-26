class Deployment

  def self.migrate
    LotteryMigration.update_selections
  end

end
