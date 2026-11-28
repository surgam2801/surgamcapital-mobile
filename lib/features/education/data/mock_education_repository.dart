import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/article.dart';
import 'education_repository.dart';

final educationRepositoryProvider = Provider<EducationRepository>(
  (ref) => MockEducationRepository(),
);

class MockEducationRepository implements EducationRepository {
  static final _articles = <EducationArticle>[
    EducationArticle(
      slug: 'mutual-fund-basics',
      title: 'Mutual Fund Basics',
      summary: 'Understand pooling, units and professional fund management.',
      icon: Icons.account_balance_outlined,
      sections: const [
        ArticleSection(
          heading: 'What is a mutual fund?',
          body:
              'A mutual fund pools money from many investors and invests it according to a stated objective. A professional fund manager manages the portfolio within the fund’s investment rules.',
        ),
        ArticleSection(
          heading: 'How units work',
          body:
              'When you invest, you receive units at the applicable net asset value (NAV). The number of units depends on the amount invested and the applicable NAV.',
        ),
      ],
    ),
    EducationArticle(
      slug: 'types-of-mutual-funds',
      title: 'Types of Mutual Funds',
      summary: 'Learn about equity, debt, hybrid and solution-oriented funds.',
      icon: Icons.category_outlined,
      sections: const [
        ArticleSection(
          heading: 'Fund categories',
          body:
              'Mutual funds may invest primarily in shares, bonds, money market instruments or a mix. Their category and scheme information document describe the intended investment strategy.',
        ),
        ArticleSection(
          heading: 'Compare carefully',
          body:
              'Compare objective, portfolio, risk, cost and liquidity. Scheme category alone does not establish that a fund is suitable for every investor.',
        ),
      ],
    ),
    EducationArticle(
      slug: 'understanding-sip',
      title: 'Understanding SIP',
      summary: 'See how periodic investing works and when it may be useful.',
      icon: Icons.autorenew,
      sections: const [
        ArticleSection(
          heading: 'A systematic investment plan',
          body:
              'A SIP is a method of investing a fixed amount at regular intervals. It does not guarantee returns and does not remove market risk.',
        ),
        ArticleSection(
          heading: 'Plan consistently',
          body:
              'Use a schedule that fits your cash flow and investment horizon. Market-linked investments can fall in value.',
        ),
      ],
    ),
    EducationArticle(
      slug: 'risk-and-returns',
      title: 'Risk and Returns',
      summary: 'Understand the relationship between risk, time and returns.',
      icon: Icons.show_chart,
      sections: const [
        ArticleSection(
          heading: 'No assured returns',
          body:
              'Market-linked mutual funds do not offer assured returns. Values can rise or fall because of market, interest-rate and credit risks.',
        ),
        ArticleSection(
          heading: 'Match the investment horizon',
          body:
              'Review the scheme riskometer, investment horizon and your ability to accept losses before choosing a category.',
        ),
      ],
    ),
    EducationArticle(
      slug: 'understanding-nav',
      title: 'Understanding NAV',
      summary:
          'Learn what NAV represents and why it is not a valuation signal.',
      icon: Icons.calculate_outlined,
      sections: const [
        ArticleSection(
          heading: 'Net asset value',
          body:
              'NAV represents the per-unit net value of the scheme’s assets after liabilities. It is calculated according to applicable regulations and scheme documents.',
        ),
        ArticleSection(
          heading: 'Do not compare NAVs alone',
          body:
              'A higher or lower NAV does not indicate a better or worse fund. Compare objective, portfolio, costs and risk instead.',
        ),
      ],
    ),
    EducationArticle(
      slug: 'portfolio-diversification',
      title: 'Portfolio Diversification',
      summary:
          'Learn why spreading investments across assets can reduce concentration.',
      icon: Icons.pie_chart_outline,
      sections: const [
        ArticleSection(
          heading: 'Diversification',
          body:
              'Diversification means spreading investments across assets that may behave differently. It may reduce concentration but cannot eliminate losses.',
        ),
        ArticleSection(
          heading: 'Review periodically',
          body:
              'Review allocation and goals over time. Diversification is not personalized advice and does not guarantee a return.',
        ),
      ],
    ),
  ];

  @override
  Future<List<EducationArticle>> getArticles() async =>
      List<EducationArticle>.unmodifiable(_articles);

  @override
  Future<EducationArticle?> getArticle(String slug) async {
    for (final article in _articles) {
      if (article.slug == slug) return article;
    }
    return null;
  }
}
