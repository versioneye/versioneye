require 'spec_helper'

describe VersioncommentsController do

  it "send_comment_mails" do
    product = ProductFactory.create_new
    user_1 = UserFactory.create_new 1
    user_2 = UserFactory.create_new 2
    product.users << user_1
    product.users << user_2

    comment = Versioncomment.new
    comment.user_id = user_1.id.to_s
    comment.product_key = product.prod_key
    comment.prod_name = product.name
    comment.language = product.language
    comment.version = "1.0.0"
    comment.comment = "comment"
    comment.save

    controller = VersioncommentsController.new
    send_to_users = controller.send("send_comment_mails", product, user_1, comment)
    expect(send_to_users.count).to eq(1)
    expect(send_to_users.first.id.to_s).to eql(user_2.id.to_s)
  end

end
