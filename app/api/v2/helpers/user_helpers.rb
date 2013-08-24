module UserHelpers

  def make_comment_response(user, page_nr, page_size)
    comments = Versioncomment.by_user( user ).paginate( page: page_nr, per_page: page_size )
    comments.each_with_index do |comment, index|
      comments[index][:user] = user
      comments[index][:product] = Product.fetch_product( comment.language, comment.product_key )
    end
    paging = make_paging_object(comments)
    user_comments = Api.new comments: comments, paging: paging
    present user_comments, with: EntitiesV2::VersionCommentEntities
  end

  def make_favorite_response(user, page_nr, page_size)
    favorites = user.products.paginate(page: page_nr, per_page: page_size)
    user_favorites = Api.new user: user,
                              favorites: favorites,
                              paging: make_paging_object(favorites)
    present user_favorites, with: EntitiesV2::UserFollowEntities
  end

end
