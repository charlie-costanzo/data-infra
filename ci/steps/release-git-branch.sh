#!/bin/bash
set -e

required_missing=()

test "$BUILD_APP"                  || required_missing+=('BUILD_APP')
test "$BUILD_ID"                   || required_missing+=('BUILD_ID')
test "$RELEASE_CHANNEL"            || required_missing+=('RELEASE_CHANNEL')
test "$RELEASE_GIT_REMOTE_NAME"    || RELEASE_GIT_REMOTE_NAME=
test "$RELEASE_GIT_REMOTE_URL"     || RELEASE_GIT_REMOTE_URL=
test "$RELEASE_GIT_COMMIT_DIRTY"   || RELEASE_GIT_COMMIT_DIRTY=

if [[ ${#required_missing[*]} -gt 0 ]]; then
  printf 'error: missing required variables: %s\n' "${required_missing[*]}" >&2
  exit 1
fi

git_branch_name=releases/$BUILD_APP/$RELEASE_CHANNEL
git_ref_remote=refs/remotes/$RELEASE_GIT_REMOTE_NAME/$git_branch_name
git_ref_local=refs/heads/$git_branch_name
git_ref_topic=$(git symbolic-ref HEAD)

# Fork release branch from remote
if [[ $RELEASE_GIT_REMOTE_NAME ]]; then

  if ! git remote | grep "^$RELEASE_GIT_REMOTE_NAME$"; then
    git remote add "$RELEASE_GIT_REMOTE_NAME" "$RELEASE_GIT_REMOTE_URL"
  elif [[ $RELEASE_GIT_REMOTE_URL != $(git remote get-url "$RELEASE_GIT_REMOTE_NAME") ]]; then
    git remote set-url "$RELEASE_GIT_REMOTE_NAME" "$RELEASE_GIT_REMOTE_URL"
  fi

  if [[ $(git ls-remote "$RELEASE_GIT_REMOTE_NAME" "$git_ref_local") ]]; then
    git fetch "$RELEASE_GIT_REMOTE_NAME" "$git_ref_local"
    git branch --no-track -f "$git_branch_name" "$git_ref_remote"
  fi

fi

# Fork release branch from local HEAD
if ! [[ $(git show-ref "$git_ref_local") ]]; then
  git branch -f "$git_branch_name"
fi

# Commit changes from dirty worktree
if [[ $RELEASE_GIT_COMMIT_DIRTY ]]; then
  git add -A
  git commit -m "rc($BUILD_APP): $BUILD_ID"
fi

# Merge topic branch into release branch
git checkout "$git_branch_name"
git merge --no-ff --no-edit -m "release($BUILD_APP/$RELEASE_CHANNEL): $BUILD_ID" "$git_ref_topic"

# Push release branch to remote
if [[ $RELEASE_GIT_REMOTE_NAME ]]; then
  git push "$RELEASE_GIT_REMOTE_NAME" "$git_ref_local":"$git_ref_local"
fi