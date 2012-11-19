module ApplicationHelper

  def title( page_title )
    content_for(:title){ page_title }
  end

  def page_header( page_header )
    content_for(:page_header){ page_header }
  end

end
