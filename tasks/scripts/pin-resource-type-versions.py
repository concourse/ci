import os
# ordered yaml so as not to change the order of keys
import oyaml as yaml

def leading_spaces(s):
    return len(s) - len(s.lstrip())

def find_next_set_pipeline(lines, from_line):
    i = from_line
    while i < len(lines) and not lines[i].lstrip().startswith("- set_pipeline:"):
        i += 1
    if i >= len(lines):
        return None, 0, 0, 0
    leading = leading_spaces(lines[i])
    j = i + 1
    while j < len(lines) and leading_spaces(lines[j]) > leading:
        j += 1
    # strip leading whitespace (and "- ") and join to a string
    step_yaml = ''.join([l[leading+2:] for l in lines[i:j]])
    return yaml.safe_load(step_yaml), leading, i, j

if __name__ == '__main__':
    release_minor = os.environ['RELEASE_MINOR']

    with open(os.environ['FILE'], 'r') as file:
        lines = file.readlines()

    with open('resource-type-versions/versions.yml', 'r') as file:
        versions = yaml.safe_load(file)

    # ~x.y.z is a semver constraint meaning "any patch versions in the x.y series >= z"
    versions = {resource_type: "~" + version for resource_type, version in versions.items()}

    i = 0
    while True:
        step, leading, i, j = find_next_set_pipeline(lines, i)
        if step is None:
            break
        if step.get('vars', {}).get('release_minor') != release_minor:
            i = j
            continue
        step['vars']['resource_type_versions'] = versions

        new_lines = yaml.dump([step], default_flow_style=False).split('\n')
        new_lines = [" " * leading + line + '\n' for line in new_lines if line]

        new_content = ''.join(lines[:i] + new_lines + lines[j+1:])
        with open(os.environ['FILE'], 'w') as file:
            file.write(new_content)
        sys.exit(0)

    print(f"could not find release pipeline with vars.release_minor = {release_minor}")
    sys.exit(1)
