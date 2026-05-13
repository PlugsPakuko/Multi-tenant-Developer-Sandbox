# Usage: ./provision.sh <student-id>
# Example: ./provision.sh 06

set -e

STUDENT_ID=$1

if [ -z "$STUDENT_ID" ]; then
  echo "Usage: ./provision.sh <student-id>"
  echo "Example: ./provision.sh 06"
  exit 1
fi

echo ">>> Provisioning sandbox for student-${STUDENT_ID}..."

# Add student to values.yaml if not already there
if grep -q "id: \"${STUDENT_ID}\"" helm/values.yaml; then
  echo "    student-${STUDENT_ID} already exists in values.yaml"
else
  # Insert new student id into the students list
  sed -i "/^students:/a\\  - id: \"${STUDENT_ID}\"" helm/values.yaml
  echo "    Added student-${STUDENT_ID} to values.yaml"
fi

# Upgrade the helm release to apply the new student
helm upgrade --install sandbox ./helm

echo ""
echo "Done! Sandbox for student-${STUDENT_ID} is ready."
echo ""
echo "Verify:"
echo "  kubectl get all -n student-${STUDENT_ID}"