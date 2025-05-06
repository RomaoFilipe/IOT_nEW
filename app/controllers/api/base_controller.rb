module Api
  class BaseController < ActionController::API


    private

    def authenticate_api!
      token = request.headers["Authorization"]&.split("Bearer ")&.last
      unless token && ActiveSupport::SecurityUtils.secure_compare(token, ENV["API_TOKEN"])
        render json: { error: "Não autorizado" }, status: :unauthorized
      end
    end
  end
end
