class StudentTaskController < ApplicationController
  helper :submitted_content
  
  def list
    if session[:user].is_new_user
      redirect_to :controller => 'eula', :action => 'display'
    end
    @participants = AssignmentParticipant.find_all_by_user_id(session[:user].id, :order => "parent_id DESC")    
  end
  
  def view
    @participant = AssignmentParticipant.find(params[:id])
    return unless current_user_id?(@participant.user_id)
    
    @assignment = @participant.assignment    
    @can_provide_suggestions = Assignment.find(@assignment.id).allow_suggestions
    @reviewee_topic_id = nil
    #Even if one of the reviewee's work is ready for review "Other's work" link should be active
    if @assignment.staggered_deadline?
      if @assignment.team_assignment
        review_mappings = TeamReviewResponseMap.find_all_by_reviewer_id(@participant.id)
      else
        review_mappings = ParticipantReviewResponseMap.find_all_by_reviewer_id(@participant.id)
      end

      review_mappings.each { |review_mapping|
          if @assignment.team_assignment
            participant = AssignmentTeam.get_first_member(review_mapping.reviewee_id)
          else
            participant = review_mapping.reviewee
          end

          if !participant.nil? and !participant.topic_id.nil?
            review_due_date = TopicDeadline.find_by_topic_id_and_deadline_type_id(participant.topic_id,1)

            if review_due_date.due_at < Time.now && @assignment.get_current_stage(participant.topic_id) != 'Complete'
              @reviewee_topic_id = participant.topic_id
            end
          end
        }
    end
  end
  
  def others_work
    @participant = AssignmentParticipant.find(params[:id])
    return unless current_user_id?(@participant.user_id)
    
    @assignment = @participant.assignment
    # Finding the current phase that we are in
    due_dates = DueDate.find(:all, :conditions => ["assignment_id = ?",@assignment.id])
    @very_last_due_date = DueDate.find(:all,:order => "due_at DESC", :limit =>1, :conditions => ["assignment_id = ?",@assignment.id])
    next_due_date = @very_last_due_date[0]
    for due_date in due_dates
      if due_date.due_at > Time.now
        if due_date.due_at < next_due_date.due_at
          next_due_date = due_date
        end
      end
    end
    
    @review_phase = next_due_date.deadline_type_id;
    if next_due_date.review_of_review_allowed_id == DueDate::LATE or next_due_date.review_of_review_allowed_id == DueDate::OK
      if @review_phase == DeadlineType.find_by_name("metareview").id
        @can_view_metareview = true
      end
    end    
    
    @review_mappings = ResponseMap.find_all_by_reviewer_id(@participant.id)
    @review_of_review_mappings = MetareviewResponseMap.find_all_by_reviewer_id(@participant.id)    
  end
  
  def your_work
    
  end
  

end
