class AliasController < BaseController
  include RestModelHelper
  before_filter :get_domain, :get_application
  def index
    rest_aliases = @application.aliases.map{ |a| get_rest_alias(a) }
    render_success(:ok, "aliases", rest_aliases, "Listing aliases for application #{@application.name} under domain #{@domain.namespace}")
  end
  
  def show   
    id = params[:id].downcase if params[:id].presence
    begin
      al1as = @application.aliases.find_by(fqdn: id)
      render_success(:ok, "alias", get_rest_alias(al1as), "Showing alias #{id} for application #{@application.name} under domain #{@domain.namespace}")
    rescue Mongoid::Errors::DocumentNotFound
      render_error(:not_found, "Alias #{id} not found for application '#{@application.name}'", 173)
    end
  end
  

  def create
    server_alias = params[:id].presence || params[:alias].presence
    ssl_certificate = params[:ssl_certificate].presence
    private_key = params[:private_key].presence
    pass_phrase = params[:pass_phrase].presence
    
    server_alias = server_alias.downcase if server_alias
    
    if ssl_certificate and (@cloud_user.capabilities["private_ssl_certificates"].nil? or @cloud_user.capabilities["private_ssl_certificates"] != true)
      return render_error(:forbidden, "User is not authorized to add private SSL certificates", 175)
    end

    result = @application.add_alias(server_alias, ssl_certificate, private_key, pass_phrase)
    rest_alias = get_rest_alias(@application.aliases.find_by(fqdn: server_alias))
    render_success(:created, "alias", rest_alias, "Added #{server_alias} to application #{@application.name}", result)
  end
  
  def update
    server_alias = params[:id].downcase if params[:id].presence
    ssl_certificate = params[:ssl_certificate].presence
    private_key = params[:private_key].presence
    pass_phrase = params[:pass_phrase].presence
    
    if ssl_certificate and (@cloud_user.capabilities["private_ssl_certificates"].nil? or @cloud_user.capabilities["private_ssl_certificates"] != true)
      return render_error(:forbidden, "User is not authorized to add private SSL certificates", 175)
    end
    
    begin 
      result = @application.update_alias(server_alias, ssl_certificate, private_key, pass_phrase)
      al1as = @application.aliases.find_by(fqdn: server_alias)
      rest_alias = get_rest_alias(al1as)
      render_success(:ok, "alias", rest_alias, "Added #{server_alias} to application #{@application.name}", result)
    rescue Mongoid::Errors::DocumentNotFound
      render_error(:not_found, "Alias #{server_alias} not found for application #{@application.name}", 173)
    end
  end
  
  def destroy
    server_alias = params[:id].downcase if params[:id].presence
    begin
      result = @application.remove_alias(server_alias)
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Alias #{server_alias} not found for application #{@application.name}", 173)
    end
    status = requested_api_version <= 1.4 ? :no_content : :ok
    render_success(status, nil, nil, "Removed #{server_alias} from application #{@application.name}", result)
  end
  
  def set_log_tag
    @log_tag = get_log_tag_prepend + "ALIAS"
  end
end
