class Admin::ProcessLogsController < AdminController

  def index
    @process_logs = ProcessLog.search(params[:search], params[:page])
  end
  
  def show
    @process_log = ProcessLog.find_by_id(params[:id])
  end

end