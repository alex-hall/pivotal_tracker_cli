require 'spec_helper'
require 'byebug'

describe PivotalTrackerCli::Client do
  context 'Pivotal Tracker API Endpoints Integration' do

    let(:api_token) { 'SECRET API TOKEN' }
    let(:project_id) { 'PROJECT ID' }
    let(:usernames) { %w(LIL_BOAT THUGGER_THUGGER) }

    let(:file_double) { double(:file, write: true) }

    user_map = {
        'LIL_BOAT' => {id: 123456, name: 'Lil\' Yachty'},
        'THUGGER_THUGGER' => {id: 444444, name: 'Young Thug'}
    }

    before do
      allow(YAML)
          .to receive(:load_file)
                  .and_return({
                                  'api_token' => api_token,
                                  'project_id' => project_id,
                                  'usernames' => usernames
                              })

      allow(PivotalTrackerCli::Api)
          .to receive(:get_all_users_for_project)
                  .with(project_id, api_token)
                  .and_return(user_map)

      String.disable_colorization = true

      allow(ENV).to receive(:[]).with(anything).and_call_original
      allow(ENV).to receive(:[]).with('HOME').and_return('HOME_PATH')
      allow(ENV).to receive(:[]).with('DISABLE_MARKDOWN').and_return('true')

      allow(File).to receive(:open).with('HOME_PATH/.pt', 'w') {}
    end


    subject {
      PivotalTrackerCli::Client.new([], {}, {})
    }

    describe 'initialize' do
      context 'when the user cache is empty' do
        it 'attempts to pull down and cache all users' do
          expect(subject.username_to_user_id_map)
              .to eq(user_map)
        end
      end
    end


    describe '#find_current_stories' do
      context 'when fetching all of a users stories' do
        context 'when all parameters are valid' do
          before do
            allow(PivotalTrackerCli::Api)
                .to receive(:get_current_stories_for_user)
                        .with(project_id, api_token, usernames)
                        .and_return([
                                        OpenStruct.new(
                                            id: 1111111,
                                            name: '**THIS** IS THE FIRST STORY',
                                            story_type: 'feature',
                                            owner_ids: [123456, 444444],
                                            description: 'SOME SUPER LONG DESCRIPTION',
                                            current_state: 'accepted'
                                        ),
                                        OpenStruct.new(
                                            id: 2222222,
                                            name: '**THIS** IS A CHORE',
                                            story_type: 'chore',
                                            owner_ids: [],
                                            description: 'SOME SUPER LONG DESCRIPTION',
                                            current_state: 'started'
                                        )])
          end

          it 'print a friendly list of stories' do
            output =
                <<~TEXT
                  ****************************************
                  Story ID          : 1111111
                  Status            : accepted
                  Story Type        : feature
                  Story Name        : **THIS** IS THE FIRST STORY
                  Owners            : Lil' Yachty, Young Thug
                  Story Description :
                                                SOME SUPER LONG DESCRIPTION
                  ****************************************
                  Story ID          : 2222222
                  Status            : started
                  Story Type        : chore
                  Story Name        : **THIS** IS A CHORE
                  Owners            : unassigned
                  Story Description :
                                                SOME SUPER LONG DESCRIPTION
                  ****************************************
            TEXT
            expect {
              subject.list
            }.to output(output).to_stdout
          end
        end
      end
    end

    context 'when manipulating story states' do
      let(:id) { 'SOME ID' }

      before do
        allow(PivotalTrackerCli::Api)
            .to receive(:update_story_state)
                    .with(project_id, api_token, id, updated_state, [123456, 444444])
                    .and_return("Story ##{id} successfully #{updated_state}.")

        allow(PivotalTrackerCli::Api)
            .to receive(:get_story_by_id)
                    .with(project_id, api_token, id).and_return('LITERALLY ANYTHING')
      end

      context 'when unstarting, starting, a story' do
        let(:updated_state) { 'started' }

        context 'and the story id exists' do
          it 'should updated the status to started' do
            expect {
              subject.update(id, 'start')
            }.to output("Story ##{id} successfully started.\n").to_stdout

          end
        end

        context 'when giving an invalid status' do
          it 'should updated the status to started' do
            expect {
              subject.update(id, 'BANANA')
            }.to output("Invalid story status. Story statuses are: unstart, start, deliver, finish\n").to_stdout

          end
        end
      end

      context 'when finishing the story' do
        before do
          allow(PivotalTrackerCli::Api)
              .to receive(:get_story_by_id)
                      .with(project_id, api_token, id).and_return(OpenStruct.new(story_type: 'story'))
        end

        let(:updated_state) { 'finished' }

        it 'should finish the story' do
          expect {
            subject.update(id, 'finish')
          }.to output("Story ##{id} successfully finished.\n").to_stdout
        end
      end
    end

    context 'when manipulating chore states' do
      let(:id) { 'SOME ID' }


      context 'when closing a chore' do
        before do
          allow(PivotalTrackerCli::Api)
              .to receive(:update_story_state)
                      .with(project_id, api_token, id, updated_state, [123456, 444444])
                      .and_return("Story ##{id} successfully #{updated_state}.")

          allow(PivotalTrackerCli::Api)
              .to receive(:get_story_by_id)
                      .with(project_id, api_token, id).and_return(OpenStruct.new(story_type: 'chore'))
        end

        let(:updated_state) { 'accepted' }

        it 'should close a chore' do
          expect {
            subject.update(id, 'finish')
          }.to output("Story ##{id} successfully accepted.\n").to_stdout
        end
      end
    end
    describe '#backlog' do
      before do
        backlog_entry = OpenStruct.new(
            id: 'SOME ID',
            story_type: 'feature',
            name: 'SOME STORY NAME',
            description: 'SOME STORY DESCRIPTION',
            current_state: 'unstarted',
            requested_by_id: 22222,
            owner_ids: [123456],
            url: 'https://www.pivotaltracker.com/story/show/1111111'
        )

        allow(PivotalTrackerCli::Api)
            .to receive(:get_backlog_for_project)
                    .and_return([backlog_entry])
      end

      it 'should return an array of backlog entries' do
        expect {
          subject.backlog
        }.to output("* SOME ID - unstarted - SOME STORY NAME <Lil' Yachty>\n").to_stdout

      end
    end
  end
end
