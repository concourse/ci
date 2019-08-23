const Octokit = require('@octokit/rest');
const { WebClient } = require('@slack/web-api');
const fs = require('fs');

const octokit = new Octokit({
  auth: process.env.GITHUB_TOKEN
});
const token = process.env.SLACK_TOKEN;
const web = new WebClient(token);
const sha = process.argv[2];
const outputFile = process.argv[3];
const owner = 'concourse';
const repo = 'concourse';

async function main() {
  var searchResults = await octokit.search.issuesAndPullRequests({
    q: `SHA=${sha}`
  });
  var commits;
  var foundPrs = searchResults.data.items;
  if (foundPrs.length > 0) {
    var pr = foundPrs[0];
    var commitsResponse = await octokit.pullRequests.listCommits({
      owner: owner,
      repo: repo,
      pull_number: pr.number
    });
    commits = commitsResponse.data.map(c => c.commit)
  } else {
    var commitResponse = await octokit.repos.getCommit({
      owner: owner,
      repo: repo,
      ref: sha
    });
    commits = [commitResponse.data.commit];
  }
  var emails = whoIsToBlame(commits);
  var slackIds = await slackIdsForEmails(emails);
  fs.writeFile(outputFile, slackMessage(slackIds), function(err) {
    if (err) {
      return console.log(err);
    }
  });
}

async function slackIdsForEmails(emails) {
  var slackIds = [];
  for (var i = 0; i < emails.length; i++) {
    var id = await slackIdForEmail(emails[i]);
    if (id) {
      slackIds.push(id);
    }
  }
  return slackIds;
}

async function slackIdForEmail(email) {
  try {
    var response = await web.users.lookupByEmail({ email : email });
    return response.user.id;
  } catch (e) {
    return null;
  }
}

function whoIsToBlame(commits) {
  return commits
    .flatMap(c => [c.author.email, c.committer.email])
    .filter((v,i,a) => a.indexOf(v) === i);
}

function slackMessage(idsToBlame) {
  if (idsToBlame.length == 0) {
    return "I don't know who to blame";
  } else if (idsToBlame.length == 1) {
    return `<@${idsToBlame[0]}> is responsible`;
  } else {
    var blameString = idsToBlame
      .map(id => `<@${id}>`)
      .join(', ')
    return `${blameString} are responsible`;
  }
}

main()
