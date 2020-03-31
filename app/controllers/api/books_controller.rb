module Api
  class BooksController < ApplicationController
    before_action :authenticate_user!, except: [:index, :show]
    before_action :set_book, only: [:show, :update]
    def index
      @nearby_users = User.near(set_coordinates, 100000, units: :km)

      @books = Book.active(@nearby_users.load.ids).includes(:owner, :book_activities, :genre, image_attachment: :blob).order(owner_id: :asc)
      @nearby_users.map {|user| [user.id, user.distance]}.flatten!
      @pagy, @books = pagy(@books, items: params[:per_page])
    end

    def show
      @distance = @book.owner.distance_to(set_coordinates, :km)
    end

    def create
      @book = @current_user.books.new(book_params)
      if @book.save
        render 'show'
      else
        @error_message = @book.errors
        render 'shared/errors', status: :unprocessable_entity
      end
    end

    def update
      if @book.update(book_params)
        render 'show'
      else
        @error_message = @book.errors
        render 'shared/errors', status: :unprocessable_entity
      end
    end

    private
    def book_params
      params.permit(:title, :author, :description, :page_count, :language, :image, :published_at, :genre_id)
    end

    def set_book
      @book = Book.find(params[:id])
    end

    def set_coordinates
      user_signed_in? ? [current_user.latitude, current_user.longitude] : [params[:latitude], params[:longitude]]
    end
  end
end
