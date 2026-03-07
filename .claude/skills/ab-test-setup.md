# A/B Test Setup Skill

Design statistically sound A/B tests for content, CTAs, headlines, and page elements.

## Test Design Framework

### Hypothesis Structure
"We believe that [change] will [outcome] because [reasoning]. We'll know this is true when [metric] improves by [X%]."

### Test Priority Matrix
Score each potential test on:
- Expected impact (1-5)
- Implementation effort (inverse, 1-5)
- Statistical confidence achievable (based on traffic)
- Learning value (1-5)

### Test Types

**Headline/Title Tests**
- Control vs. variant H1 or page title
- One variable: formula, length, or keyword position

**CTA Tests**
- Button copy: "Start Free Trial" vs. "Get Started Free"
- Button color, size, placement
- Offer type: trial vs. demo vs. freemium

**Copy Tests**
- Long vs. short above-fold copy
- Feature-led vs. benefit-led
- Social proof placement

**Meta Description Tests**
- CTR optimization in Search Console
- Test via Search Console Performance data

## Statistical Requirements

- Minimum sample size calculator: need at least 100 conversions per variant
- Confidence level: 95% minimum
- Test duration: minimum 2 weeks (avoid day-of-week bias)
- One variable at a time

## Usage

Provide:
1. Page or element to test
2. Current performance metric
3. Hypothesis for improvement
4. Available traffic volume

## Output

- Test plan with control and variant defined
- Success metrics and measurement method
- Minimum run time calculation
- How to analyze results
