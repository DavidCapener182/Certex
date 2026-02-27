import React, { useMemo, useState } from 'react';
import {
  CheckCircle2,
  AlertTriangle,
  ShieldCheck,
  KeyRound,
  Link2,
  Building2,
  Users,
  Workflow,
  FileCheck2,
  Plus,
  ArrowRight,
  RefreshCcw,
  Smartphone,
  Lock,
  ServerCog,
  Gauge,
} from 'lucide-react';
import { summarizeReleaseGateStatus, summarizeRiskSignals } from './lib/opsScoring';

function formatCurrencyGBP(value) {
  const amount = Number(value || 0);
  return new Intl.NumberFormat('en-GB', {
    style: 'currency',
    currency: 'GBP',
    maximumFractionDigits: 2,
  }).format(Number.isFinite(amount) ? amount : 0);
}

function OpsMetricCard({ title, value, tone = 'slate', helper = '' }) {
  const toneClasses = {
    slate: 'bg-slate-50 dark:bg-slate-900/35 border-slate-200 dark:border-slate-700 text-slate-800 dark:text-slate-100',
    cyan: 'bg-cyan-50 dark:bg-cyan-900/25 border-cyan-200 dark:border-cyan-800/40 text-cyan-800 dark:text-cyan-200',
    emerald:
      'bg-emerald-50 dark:bg-emerald-900/25 border-emerald-200 dark:border-emerald-800/40 text-emerald-800 dark:text-emerald-200',
    amber:
      'bg-amber-50 dark:bg-amber-900/25 border-amber-200 dark:border-amber-800/40 text-amber-800 dark:text-amber-200',
    rose: 'bg-rose-50 dark:bg-rose-900/25 border-rose-200 dark:border-rose-800/40 text-rose-800 dark:text-rose-200',
    indigo:
      'bg-indigo-50 dark:bg-indigo-900/25 border-indigo-200 dark:border-indigo-800/40 text-indigo-800 dark:text-indigo-200',
  };

  return (
    <article className={`rounded-xl border px-3 py-3 ${toneClasses[tone] || toneClasses.slate}`}>
      <p className="text-[11px] font-bold uppercase tracking-wider opacity-80">{title}</p>
      <p className="text-lg font-black mt-1">{value}</p>
      {helper ? <p className="text-[11px] mt-1 opacity-75">{helper}</p> : null}
    </article>
  );
}

function SectionCard({ title, subtitle, actions = null, children }) {
  return (
    <section className="rounded-2xl border border-slate-200 dark:border-slate-700 bg-white/85 dark:bg-slate-800/75 p-4 shadow-sm">
      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-3 mb-3">
        <div>
          <p className="text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">{title}</p>
          {subtitle ? <p className="text-xs text-slate-600 dark:text-slate-300 mt-1">{subtitle}</p> : null}
        </div>
        {actions ? <div className="flex flex-wrap gap-2">{actions}</div> : null}
      </div>
      {children}
    </section>
  );
}

export default function OperationsCenterView({
  isSupabaseConfigured = false,
  authRuntimeMode = 'mock',
  onSetAuthRuntimeMode,
  tenantInvites = [],
  onCreateTenantInvite,
  onAcceptTenantInvite,
  marketplaceBidBoard = [],
  dispatchSlaEvents = [],
  onSeedBidRound,
  onAwardBestBid,
  templateBlueprints = [],
  onPublishTemplateBlueprint,
  evidenceAiJobs = [],
  evidenceProvenanceEvents = [],
  onQueueEvidenceAiJob,
  onAdvanceEvidenceReview,
  onAppendProvenanceEvent,
  regulatorVerificationRequests = [],
  onCreateVerificationRequest,
  onResolveVerificationRequest,
  auditFindings = [],
  auditActions = [],
  onCreateAuditAction,
  onAdvanceAuditActionStatus,
  financeInvoices = [],
  payoutRuns = [],
  onGenerateInvoices,
  onSchedulePayout,
  analyticsRiskSignals = [],
  integrationConnections = [],
  apiClients = [],
  webhookEndpoints = [],
  webhookDeliveryEvents = [],
  onCreateApiClient,
  onRotateApiClientSecret,
  onCreateWebhookEndpoint,
  onTriggerWebhookRetry,
  mobileAuditSessions = [],
  onOpenMobileSession,
  enterpriseSsoProviders = [],
  enterpriseAccessPolicies = [],
  enterpriseSecurityEvents = [],
  onConfigureSsoProvider,
  onToggleEnterprisePolicy,
  onLogSecurityEvent,
  qaHarnessRuns = [],
  releaseGateResults = [],
  onStartQaHarnessRun,
  onFinalizeQaHarnessRun,
  onAdvanceReleaseGateResult,
}) {
  const [inviteEmail, setInviteEmail] = useState('');
  const [inviteRole, setInviteRole] = useState('dutyholder_admin');
  const [apiClientName, setApiClientName] = useState('');
  const [webhookName, setWebhookName] = useState('');
  const [webhookUrl, setWebhookUrl] = useState('');
  const [ssoProviderName, setSsoProviderName] = useState('Microsoft Entra ID');
  const [ssoDomain, setSsoDomain] = useState('');
  const [activeOpsTab, setActiveOpsTab] = useState('overview');

  const openInvites = tenantInvites.filter((invite) => invite.status === 'pending').length;
  const submittedBids = marketplaceBidBoard.filter((bid) => bid.status === 'submitted').length;
  const awardedBids = marketplaceBidBoard.filter((bid) => bid.status === 'awarded').length;
  const aiQueued = evidenceAiJobs.filter((job) => job.status === 'queued').length;
  const aiPendingReview = evidenceAiJobs.filter(
    (job) => job.status === 'completed' && String(job.reviewDecision || '') === 'pending'
  ).length;
  const openVerification = regulatorVerificationRequests.filter((item) => item.status === 'open').length;
  const openActions = auditActions.filter((item) => item.status !== 'closed').length;
  const pendingInvoices = financeInvoices.filter((item) => item.status === 'pending_approval').length;
  const failedWebhooks = webhookDeliveryEvents.filter((item) => item.status === 'failed').length;
  const activeApiClients = apiClients.filter((item) => item.status === 'active').length;
  const activeWebhookEndpoints = webhookEndpoints.filter((item) => item.status === 'active').length;
  const activeMobile = mobileAuditSessions.filter((item) => !item.closedAt).length;
  const configuredSsoProviders = enterpriseSsoProviders.filter((item) => item.status === 'configured').length;
  const enabledEnterprisePolicies = enterpriseAccessPolicies.filter((item) => item.status === 'enabled').length;
  const highSecurityEvents = enterpriseSecurityEvents.filter((item) => item.severity === 'high').length;
  const runningQa = qaHarnessRuns.filter((item) => item.status === 'running').length;
  const pendingGates = releaseGateResults.filter((item) => item.status === 'pending').length;
  const riskSummary = summarizeRiskSignals(analyticsRiskSignals);
  const gateSummary = summarizeReleaseGateStatus(releaseGateResults);
  const highRiskSignals = riskSummary.high;
  const publishedTemplates = templateBlueprints.filter((item) => item.status === 'published').length;
  const operationsTabs = [
    {
      id: 'overview',
      label: 'Overview',
      helper: 'Readiness status across all delivery tracks.',
    },
    {
      id: 'onboarding',
      label: 'Onboarding',
      helper: 'Tenant auth setup and invite flow.',
      badge: openInvites,
    },
    {
      id: 'marketplace',
      label: 'Bidding',
      helper: 'Bid rounds, award decisions, and dispatch telemetry.',
      badge: submittedBids,
    },
    {
      id: 'evidence',
      label: 'Evidence',
      helper: 'Template lifecycle, AI review queue, and verification.',
      badge: aiPendingReview + openVerification,
    },
    {
      id: 'finance',
      label: 'CAPA + Finance',
      helper: 'Corrective actions, invoicing, and payout scheduling.',
      badge: openActions + pendingInvoices,
    },
    {
      id: 'platform',
      label: 'Platform + QA',
      helper: 'Integrations, enterprise controls, and release quality.',
      badge: failedWebhooks + pendingGates,
    },
  ];
  const activeOpsTabMeta = operationsTabs.find((tab) => tab.id === activeOpsTab) || operationsTabs[0];

  const nextInvoiceForPayout = useMemo(
    () => financeInvoices.find((invoice) => invoice.status === 'approved') || null,
    [financeInvoices]
  );

  const handleCreateInvite = (event) => {
    event.preventDefault();
    const trimmedEmail = String(inviteEmail || '').trim().toLowerCase();
    if (!trimmedEmail) {
      return;
    }
    const didCreate = onCreateTenantInvite?.(trimmedEmail, inviteRole);
    if (didCreate !== false) {
      setInviteEmail('');
    }
  };

  const handleCreateApiClient = () => {
    const normalizedName = String(apiClientName || '').trim();
    const didCreate = onCreateApiClient?.(normalizedName || undefined);
    if (didCreate !== false) {
      setApiClientName('');
    }
  };

  const handleCreateWebhookEndpoint = () => {
    const normalizedName = String(webhookName || '').trim();
    const normalizedUrl = String(webhookUrl || '').trim();
    const didCreate = onCreateWebhookEndpoint?.({
      name: normalizedName,
      targetUrl: normalizedUrl,
    });
    if (didCreate !== false) {
      setWebhookName('');
      setWebhookUrl('');
    }
  };

  const handleConfigureSsoProvider = () => {
    const normalizedName = String(ssoProviderName || '').trim();
    const normalizedDomain = String(ssoDomain || '').trim();
    const didConfigure = onConfigureSsoProvider?.(normalizedName, normalizedDomain);
    if (didConfigure !== false) {
      setSsoDomain('');
    }
  };

  return (
    <div className="space-y-5 animate-in fade-in duration-300 pb-10">
      <section className="rounded-2xl border border-slate-200 dark:border-slate-700 bg-white/85 dark:bg-slate-800/75 p-5 shadow-sm">
        <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-3">
          <div>
            <p className="text-xs font-bold uppercase tracking-wider text-cyan-600 dark:text-cyan-400">InCert Operations</p>
            <h2 className="text-2xl font-black text-slate-900 dark:text-white mt-1">Production Readiness Console</h2>
            <p className="text-sm text-slate-600 dark:text-slate-300 mt-2">
              Tracks delivery progress for auth, bidding, template studio, evidence trust, CAPA/finance, integrations, and release quality.
            </p>
          </div>
          <div className="rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-900/35 p-3">
            <p className="text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">Auth runtime mode</p>
            <div className="mt-2 inline-flex rounded-lg border border-slate-200 dark:border-slate-700 overflow-hidden">
              <button
                type="button"
                onClick={() => onSetAuthRuntimeMode?.('mock')}
                className={`px-3 py-1.5 text-xs font-bold ${authRuntimeMode === 'mock' ? 'bg-cyan-600 text-white' : 'bg-white dark:bg-slate-900/40 text-slate-600 dark:text-slate-300'}`}
              >
                Mock
              </button>
              <button
                type="button"
                onClick={() => onSetAuthRuntimeMode?.('supabase')}
                className={`px-3 py-1.5 text-xs font-bold border-l border-slate-200 dark:border-slate-700 ${
                  authRuntimeMode === 'supabase' ? 'bg-cyan-600 text-white' : 'bg-white dark:bg-slate-900/40 text-slate-600 dark:text-slate-300'
                }`}
              >
                Supabase
              </button>
            </div>
            <p className="text-[11px] mt-2 text-slate-500 dark:text-slate-400">
              {isSupabaseConfigured ? 'Supabase env detected.' : 'Supabase env not configured yet.'}
            </p>
          </div>
        </div>
      </section>

      <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-6">
        <OpsMetricCard title="Open Invites" value={openInvites} tone="cyan" />
        <OpsMetricCard title="Submitted/Awarded Bids" value={`${submittedBids}/${awardedBids}`} tone="indigo" />
        <OpsMetricCard title="AI Queue/Review" value={`${aiQueued}/${aiPendingReview}`} tone="amber" />
        <OpsMetricCard title="Open CAPA Actions" value={openActions} tone={openActions > 0 ? 'amber' : 'emerald'} />
        <OpsMetricCard title="High Risk Signals" value={highRiskSignals} tone={highRiskSignals > 0 ? 'rose' : 'emerald'} />
        <OpsMetricCard title="Pending Gates" value={pendingGates} tone={pendingGates > 0 ? 'amber' : 'emerald'} helper={gateSummary.releaseReadiness} />
      </div>

      <section className="rounded-2xl border border-slate-200 dark:border-slate-700 bg-white/85 dark:bg-slate-800/75 p-3 shadow-sm">
        <div className="flex flex-wrap gap-2" role="tablist" aria-label="Operations dashboard sections">
          {operationsTabs.map((tab) => {
            const isActive = activeOpsTab === tab.id;
            return (
              <button
                key={tab.id}
                type="button"
                id={`ops-tab-${tab.id}`}
                role="tab"
                aria-selected={isActive}
                aria-controls="ops-panel"
                onClick={() => setActiveOpsTab(tab.id)}
                className={`px-3 py-1.5 rounded-lg text-xs font-bold border transition ${
                  isActive
                    ? 'bg-cyan-600 border-cyan-600 text-white'
                    : 'bg-white dark:bg-slate-900/45 border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300'
                }`}
              >
                {tab.label}
                {typeof tab.badge === 'number' ? (
                  <span className={`ml-2 rounded-full px-1.5 py-0.5 text-[10px] ${isActive ? 'bg-white/20 text-white' : 'bg-slate-200 dark:bg-slate-700 text-slate-700 dark:text-slate-200'}`}>
                    {tab.badge}
                  </span>
                ) : null}
              </button>
            );
          })}
        </div>
        <p className="text-xs text-slate-500 dark:text-slate-400 mt-2">{activeOpsTabMeta.helper}</p>
      </section>

      <div id="ops-panel" role="tabpanel" aria-labelledby={`ops-tab-${activeOpsTab}`} className="space-y-5">
      {activeOpsTab === 'onboarding' ? (
      <SectionCard
        title="Tenant Auth + Onboarding"
        subtitle="Prepare invite-driven org access while Supabase project is finishing."
        actions={
          <button
            type="button"
            onClick={() => tenantInvites.find((item) => item.status === 'pending') && onAcceptTenantInvite?.()}
            className="px-3 py-1.5 rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold"
          >
            Accept Next Invite
          </button>
        }
      >
        <div className="grid gap-3 lg:grid-cols-[1fr_1.2fr]">
          <form onSubmit={handleCreateInvite} className="rounded-xl border border-slate-200 dark:border-slate-700 bg-slate-50/70 dark:bg-slate-900/35 p-3 space-y-2">
            <p className="text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">Create invite</p>
            <input
              type="email"
              required
              value={inviteEmail}
              onChange={(event) => setInviteEmail(event.target.value)}
              placeholder="ops@customer.com"
              className="w-full px-3 py-2 rounded-lg text-sm bg-white dark:bg-slate-900/55 border border-slate-200 dark:border-slate-700"
            />
            <select
              value={inviteRole}
              onChange={(event) => setInviteRole(event.target.value)}
              className="w-full px-3 py-2 rounded-lg text-sm bg-white dark:bg-slate-900/55 border border-slate-200 dark:border-slate-700"
            >
              <option value="dutyholder_admin">Dutyholder Admin</option>
              <option value="site_manager">Site Manager</option>
              <option value="provider_admin">Provider Admin</option>
              <option value="insurer_viewer">Insurer Viewer</option>
            </select>
            <button type="submit" className="px-3 py-2 rounded-lg bg-cyan-600 hover:bg-cyan-700 text-white text-xs font-bold inline-flex items-center gap-1.5">
              <Plus className="w-3.5 h-3.5" />
              Send Invite
            </button>
          </form>

          <div className="space-y-2">
            {tenantInvites.slice(0, 5).map((invite) => (
              <div key={invite.id} className="rounded-lg border border-slate-200 dark:border-slate-700 bg-white/70 dark:bg-slate-900/40 px-3 py-2">
                <p className="text-xs font-semibold text-slate-800 dark:text-slate-100">
                  {invite.id} • {invite.email}
                </p>
                <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-1">
                  {invite.role} • {invite.status} • {invite.sentAt}
                </p>
              </div>
            ))}
            {tenantInvites.length === 0 ? (
              <p className="text-xs text-slate-500 dark:text-slate-400">No invites created yet.</p>
            ) : null}
          </div>
        </div>
      </SectionCard>
      ) : null}

      {activeOpsTab === 'marketplace' ? (
      <SectionCard
        title="Bidding + Dispatch Intelligence"
        subtitle="Audit-company bid rounds, award decisions, and SLA telemetry."
        actions={
          <>
            <button
              type="button"
              onClick={() => onSeedBidRound?.()}
              className="px-3 py-1.5 rounded-lg bg-cyan-600 hover:bg-cyan-700 text-white text-xs font-bold inline-flex items-center gap-1.5"
            >
              <Plus className="w-3.5 h-3.5" />
              Seed Round
            </button>
            <button
              type="button"
              onClick={() => onAwardBestBid?.()}
              className="px-3 py-1.5 rounded-lg bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-bold inline-flex items-center gap-1.5"
            >
              <Workflow className="w-3.5 h-3.5" />
              Auto-Award
            </button>
          </>
        }
      >
        <div className="grid gap-3 lg:grid-cols-2">
          <div className="space-y-2">
            {marketplaceBidBoard.slice(0, 4).map((bid) => (
              <div key={bid.id} className="rounded-lg border border-slate-200 dark:border-slate-700 bg-white/70 dark:bg-slate-900/40 px-3 py-2">
                <p className="text-xs font-semibold text-slate-800 dark:text-slate-100">{bid.id} • {bid.requestId}</p>
                <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-1">
                  {bid.providerOrgName} • {bid.status} • score {bid.rankScore} • {formatCurrencyGBP(bid.totalExVat)} ex VAT
                </p>
              </div>
            ))}
          </div>
          <div className="space-y-2">
            {dispatchSlaEvents.slice(0, 4).map((event) => (
              <div key={event.id} className="rounded-lg border border-slate-200 dark:border-slate-700 bg-white/70 dark:bg-slate-900/40 px-3 py-2">
                <p className="text-xs font-semibold text-slate-800 dark:text-slate-100">{event.id} • {event.requestId}</p>
                <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-1">
                  {event.eventType} • {event.minutesFromOpen} mins from open • {event.isBreach ? 'breach' : 'in SLA'}
                </p>
              </div>
            ))}
          </div>
        </div>
      </SectionCard>
      ) : null}

      {activeOpsTab === 'evidence' ? (
      <SectionCard
        title="Template Studio + Evidence Trust"
        subtitle="Template publishing, AI evidence review, provenance chain, and regulator verification."
        actions={
          <>
            <button
              type="button"
              onClick={() => templateBlueprints.find((template) => template.status !== 'published') && onPublishTemplateBlueprint?.(templateBlueprints.find((template) => template.status !== 'published')?.id, 'Published via Ops Console')}
              className="px-3 py-1.5 rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold"
            >
              Publish Next Template
            </button>
            <button
              type="button"
              onClick={() => onQueueEvidenceAiJob?.()}
              className="px-3 py-1.5 rounded-lg bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-bold"
            >
              Queue AI Job
            </button>
            <button
              type="button"
              onClick={() => onAppendProvenanceEvent?.()}
              className="px-3 py-1.5 rounded-lg bg-cyan-600 hover:bg-cyan-700 text-white text-xs font-bold"
            >
              Add Provenance
            </button>
          </>
        }
      >
        <div className="grid gap-3 lg:grid-cols-3">
          <div className="space-y-2">
            <p className="text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
              Templates ({publishedTemplates} published)
            </p>
            {templateBlueprints.slice(0, 3).map((template) => (
              <div key={template.id} className="rounded-lg border border-slate-200 dark:border-slate-700 bg-white/70 dark:bg-slate-900/40 px-3 py-2">
                <p className="text-xs font-semibold text-slate-800 dark:text-slate-100">{template.id} • {template.name}</p>
                <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-1">
                  {template.status} • v{template.currentVersion} • {template.scoringModel}
                </p>
              </div>
            ))}
          </div>
          <div className="space-y-2">
            <p className="text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
              AI Evidence ({aiQueued} queued)
            </p>
            {evidenceAiJobs.slice(0, 3).map((job) => (
              <div key={job.id} className="rounded-lg border border-slate-200 dark:border-slate-700 bg-white/70 dark:bg-slate-900/40 px-3 py-2">
                <p className="text-xs font-semibold text-slate-800 dark:text-slate-100">{job.id}</p>
                <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-1">{job.status} • review {job.reviewDecision}</p>
              </div>
            ))}
            <button
              type="button"
              onClick={() => onAdvanceEvidenceReview?.()}
              className="px-2.5 py-1 rounded-full bg-indigo-100 text-indigo-700 dark:bg-indigo-900/40 dark:text-indigo-300 text-[11px] font-bold"
            >
              Advance Evidence Review
            </button>
          </div>
          <div className="space-y-2">
            <p className="text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
              Provenance + Verification
            </p>
            {evidenceProvenanceEvents.slice(0, 2).map((event) => (
              <div key={event.id} className="rounded-lg border border-slate-200 dark:border-slate-700 bg-white/70 dark:bg-slate-900/40 px-3 py-2">
                <p className="text-xs font-semibold text-slate-800 dark:text-slate-100">{event.id} • {event.eventType}</p>
                <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-1">{event.evidenceRef}</p>
              </div>
            ))}
            {regulatorVerificationRequests.slice(0, 2).map((request) => (
              <div key={request.id} className="rounded-lg border border-slate-200 dark:border-slate-700 bg-white/70 dark:bg-slate-900/40 px-3 py-2">
                <p className="text-xs font-semibold text-slate-800 dark:text-slate-100">{request.id} • {request.status}</p>
                <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-1">{request.referenceId}</p>
              </div>
            ))}
            <div className="flex flex-wrap gap-2">
              <button
                type="button"
                onClick={() => onCreateVerificationRequest?.()}
                className="px-2.5 py-1 rounded-full bg-cyan-100 text-cyan-700 dark:bg-cyan-900/40 dark:text-cyan-300 text-[11px] font-bold"
              >
                New Verification Request
              </button>
              {openVerification > 0 ? (
                <button
                  type="button"
                  onClick={() => onResolveVerificationRequest?.()}
                  className="px-2.5 py-1 rounded-full bg-emerald-100 text-emerald-700 dark:bg-emerald-900/40 dark:text-emerald-300 text-[11px] font-bold"
                >
                  Resolve One
                </button>
              ) : null}
            </div>
          </div>
        </div>
      </SectionCard>
      ) : null}

      {activeOpsTab === 'finance' ? (
      <SectionCard
        title="CAPA + Finance Automation"
        subtitle="Finding-driven actions, invoice generation, and payout scheduling."
        actions={
          <>
            <button
              type="button"
              onClick={() => onCreateAuditAction?.()}
              className="px-3 py-1.5 rounded-lg bg-amber-600 hover:bg-amber-700 text-white text-xs font-bold"
            >
              Create CAPA Action
            </button>
            <button
              type="button"
              onClick={() => onGenerateInvoices?.()}
              className="px-3 py-1.5 rounded-lg bg-cyan-600 hover:bg-cyan-700 text-white text-xs font-bold"
            >
              Generate Invoices
            </button>
            {nextInvoiceForPayout ? (
              <button
                type="button"
                onClick={() => onSchedulePayout?.(nextInvoiceForPayout.id)}
                className="px-3 py-1.5 rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold"
              >
                Schedule Next Payout
              </button>
            ) : null}
          </>
        }
      >
        <div className="grid gap-3 lg:grid-cols-3">
          <OpsMetricCard title="Open Findings" value={auditFindings.filter((item) => item.status !== 'closed').length} tone="amber" />
          <OpsMetricCard title="Open Actions" value={openActions} tone={openActions > 0 ? 'amber' : 'emerald'} />
          <OpsMetricCard title="Pending Invoices" value={pendingInvoices} tone={pendingInvoices > 0 ? 'amber' : 'emerald'} helper={`${payoutRuns.length} payout runs`} />
        </div>
        <div className="mt-3 flex flex-wrap gap-2">
          <button
            type="button"
            onClick={() => onAdvanceAuditActionStatus?.(auditActions.find((item) => item.status !== 'closed')?.id)}
            className="px-3 py-1.5 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900/40 text-xs font-bold text-slate-700 dark:text-slate-200 inline-flex items-center gap-1.5"
          >
            Advance Next Action <ArrowRight className="w-3.5 h-3.5" />
          </button>
        </div>
      </SectionCard>
      ) : null}

      {activeOpsTab === 'platform' ? (
      <SectionCard
        title="Integrations + Mobile + Enterprise + Quality"
        subtitle="Webhook retries, mobile session hardening, security events, and release gates."
        actions={
          <>
            <button
              type="button"
              onClick={() => onTriggerWebhookRetry?.()}
              className="px-3 py-1.5 rounded-lg bg-amber-600 hover:bg-amber-700 text-white text-xs font-bold inline-flex items-center gap-1.5"
            >
              <RefreshCcw className="w-3.5 h-3.5" />
              Retry Webhook
            </button>
            <button
              type="button"
              onClick={() => onOpenMobileSession?.()}
              className="px-3 py-1.5 rounded-lg bg-cyan-600 hover:bg-cyan-700 text-white text-xs font-bold inline-flex items-center gap-1.5"
            >
              <Smartphone className="w-3.5 h-3.5" />
              Open Mobile Session
            </button>
            <button
              type="button"
              onClick={() => onLogSecurityEvent?.()}
              className="px-3 py-1.5 rounded-lg bg-rose-600 hover:bg-rose-700 text-white text-xs font-bold inline-flex items-center gap-1.5"
            >
              <Lock className="w-3.5 h-3.5" />
              Log Security Event
            </button>
          </>
        }
      >
        <div className="grid gap-3 lg:grid-cols-6">
          <OpsMetricCard title="Connected Integrations" value={integrationConnections.filter((item) => item.status === 'connected').length} tone="cyan" />
          <OpsMetricCard title="API Clients" value={activeApiClients} tone="indigo" />
          <OpsMetricCard title="Webhook Endpoints" value={activeWebhookEndpoints} tone="cyan" />
          <OpsMetricCard title="Failed Webhooks" value={failedWebhooks} tone={failedWebhooks > 0 ? 'amber' : 'emerald'} />
          <OpsMetricCard title="Active Mobile Sessions" value={activeMobile} tone="indigo" />
          <OpsMetricCard
            title="Enterprise Controls"
            value={`${configuredSsoProviders}/${enabledEnterprisePolicies}`}
            tone={configuredSsoProviders > 0 && enabledEnterprisePolicies > 0 ? 'emerald' : 'amber'}
            helper="SSO providers / enabled policies"
          />
        </div>

        <div className="mt-3 grid gap-3 xl:grid-cols-[1.15fr_1fr]">
          <div className="space-y-3">
            <div className="rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50/75 dark:bg-slate-900/35 p-3 space-y-2">
              <p className="text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">API Clients + Webhooks</p>
              <div className="grid gap-2 md:grid-cols-2">
                <input
                  type="text"
                  value={apiClientName}
                  onChange={(event) => setApiClientName(event.target.value)}
                  placeholder="API client name"
                  className="px-3 py-2 rounded-lg text-xs bg-white dark:bg-slate-900/55 border border-slate-200 dark:border-slate-700"
                />
                <button
                  type="button"
                  onClick={handleCreateApiClient}
                  className="px-3 py-2 rounded-lg bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-bold inline-flex items-center justify-center gap-1.5"
                >
                  <KeyRound className="w-3.5 h-3.5" />
                  Create API Client
                </button>
                <input
                  type="text"
                  value={webhookName}
                  onChange={(event) => setWebhookName(event.target.value)}
                  placeholder="Webhook label"
                  className="px-3 py-2 rounded-lg text-xs bg-white dark:bg-slate-900/55 border border-slate-200 dark:border-slate-700"
                />
                <input
                  type="url"
                  value={webhookUrl}
                  onChange={(event) => setWebhookUrl(event.target.value)}
                  placeholder="https://target.example/hook"
                  className="px-3 py-2 rounded-lg text-xs bg-white dark:bg-slate-900/55 border border-slate-200 dark:border-slate-700"
                />
              </div>
              <button
                type="button"
                onClick={handleCreateWebhookEndpoint}
                className="px-3 py-2 rounded-lg bg-cyan-600 hover:bg-cyan-700 text-white text-xs font-bold inline-flex items-center gap-1.5"
              >
                <Link2 className="w-3.5 h-3.5" />
                Add Webhook Endpoint
              </button>

              <div className="space-y-2">
                {apiClients.slice(0, 3).map((client) => (
                  <div key={client.id} className="rounded-lg border border-slate-200 dark:border-slate-700 bg-white/75 dark:bg-slate-900/45 px-3 py-2">
                    <p className="text-xs font-semibold text-slate-800 dark:text-slate-100">{client.id} • {client.name}</p>
                    <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-1">
                      {client.status} • secret {client.secretFingerprint}
                    </p>
                    <button
                      type="button"
                      onClick={() => onRotateApiClientSecret?.(client.id)}
                      className="mt-2 px-2.5 py-1 rounded-full bg-indigo-100 text-indigo-700 dark:bg-indigo-900/40 dark:text-indigo-300 text-[11px] font-bold"
                    >
                      Rotate Secret
                    </button>
                  </div>
                ))}
                {webhookEndpoints.slice(0, 2).map((endpoint) => (
                  <div key={endpoint.id} className="rounded-lg border border-slate-200 dark:border-slate-700 bg-white/75 dark:bg-slate-900/45 px-3 py-2">
                    <p className="text-xs font-semibold text-slate-800 dark:text-slate-100">{endpoint.id} • {endpoint.name}</p>
                    <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-1">{endpoint.targetUrl}</p>
                  </div>
                ))}
              </div>
            </div>

            <div className="rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50/75 dark:bg-slate-900/35 p-3 space-y-2">
              <p className="text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">Enterprise SSO + Access Policies</p>
              <div className="grid gap-2 md:grid-cols-2">
                <input
                  type="text"
                  value={ssoProviderName}
                  onChange={(event) => setSsoProviderName(event.target.value)}
                  placeholder="SSO provider"
                  className="px-3 py-2 rounded-lg text-xs bg-white dark:bg-slate-900/55 border border-slate-200 dark:border-slate-700"
                />
                <input
                  type="text"
                  value={ssoDomain}
                  onChange={(event) => setSsoDomain(event.target.value)}
                  placeholder="company.example"
                  className="px-3 py-2 rounded-lg text-xs bg-white dark:bg-slate-900/55 border border-slate-200 dark:border-slate-700"
                />
              </div>
              <button
                type="button"
                onClick={handleConfigureSsoProvider}
                className="px-3 py-2 rounded-lg bg-rose-600 hover:bg-rose-700 text-white text-xs font-bold inline-flex items-center gap-1.5"
              >
                <Building2 className="w-3.5 h-3.5" />
                Configure SSO
              </button>
              <div className="space-y-2">
                {enterpriseSsoProviders.slice(0, 3).map((provider) => (
                  <div key={provider.id} className="rounded-lg border border-slate-200 dark:border-slate-700 bg-white/75 dark:bg-slate-900/45 px-3 py-2">
                    <p className="text-xs font-semibold text-slate-800 dark:text-slate-100">{provider.id} • {provider.providerName}</p>
                    <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-1">
                      {provider.status} • domain {provider.domain}
                    </p>
                  </div>
                ))}
                {enterpriseAccessPolicies.slice(0, 3).map((policy) => (
                  <div key={policy.id} className="rounded-lg border border-slate-200 dark:border-slate-700 bg-white/75 dark:bg-slate-900/45 px-3 py-2 flex items-center justify-between gap-2">
                    <div>
                      <p className="text-xs font-semibold text-slate-800 dark:text-slate-100">{policy.id} • {policy.name}</p>
                      <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-1">{policy.status}</p>
                    </div>
                    <button
                      type="button"
                      onClick={() => onToggleEnterprisePolicy?.(policy.id)}
                      className="px-2.5 py-1 rounded-full bg-slate-200 text-slate-700 dark:bg-slate-700 dark:text-slate-200 text-[11px] font-bold"
                    >
                      Toggle
                    </button>
                  </div>
                ))}
              </div>
            </div>
          </div>

          <div className="space-y-2">
            {qaHarnessRuns.slice(0, 3).map((run) => (
              <div key={run.id} className="rounded-lg border border-slate-200 dark:border-slate-700 bg-white/70 dark:bg-slate-900/40 px-3 py-2">
                <p className="text-xs font-semibold text-slate-800 dark:text-slate-100">
                  <ServerCog className="w-3.5 h-3.5 inline mr-1" />
                  {run.id} • {run.suiteName}
                </p>
                <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-1">{run.status} • pass rate {run.passRate}%</p>
              </div>
            ))}
            <div className="flex flex-wrap gap-2">
              <button
                type="button"
                onClick={() => onStartQaHarnessRun?.()}
                className="px-2.5 py-1 rounded-full bg-cyan-100 text-cyan-700 dark:bg-cyan-900/40 dark:text-cyan-300 text-[11px] font-bold"
              >
                Start QA Run
              </button>
              {runningQa > 0 ? (
                <button
                  type="button"
                  onClick={() => onFinalizeQaHarnessRun?.()}
                  className="px-2.5 py-1 rounded-full bg-emerald-100 text-emerald-700 dark:bg-emerald-900/40 dark:text-emerald-300 text-[11px] font-bold"
                >
                  Finalize Running QA
                </button>
              ) : null}
            </div>
            <p className="text-[11px] text-slate-500 dark:text-slate-400">
              High security events: {highSecurityEvents}
            </p>
          </div>

          <div className="space-y-2">
            {releaseGateResults.slice(0, 3).map((gate) => (
              <div key={gate.id} className="rounded-lg border border-slate-200 dark:border-slate-700 bg-white/70 dark:bg-slate-900/40 px-3 py-2">
                <p className="text-xs font-semibold text-slate-800 dark:text-slate-100">
                  <Gauge className="w-3.5 h-3.5 inline mr-1" />
                  {gate.id} • {gate.gateName}
                </p>
                <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-1">{gate.status} • {gate.notes}</p>
              </div>
            ))}
            <button
              type="button"
              onClick={() => onAdvanceReleaseGateResult?.()}
              className="px-2.5 py-1 rounded-full bg-slate-200 text-slate-700 dark:bg-slate-700 dark:text-slate-200 text-[11px] font-bold"
            >
              Advance Gate
            </button>
          </div>
        </div>
        <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-3">
          Risk summary: {riskSummary.high} high / {riskSummary.medium} medium / {riskSummary.low} low • Release readiness: {gateSummary.releaseReadiness}
        </p>
      </SectionCard>
      ) : null}

      {activeOpsTab === 'overview' ? (
      <section className="rounded-2xl border border-slate-200 dark:border-slate-700 bg-white/85 dark:bg-slate-800/75 p-4 shadow-sm">
        <p className="text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-3">Readiness at a glance</p>
        <div className="grid gap-2 md:grid-cols-3 lg:grid-cols-6">
          {[
            { label: 'Auth + Tenant', done: isSupabaseConfigured && authRuntimeMode === 'supabase' && openInvites === 0, icon: Users },
            { label: 'Bid Engine', done: marketplaceBidBoard.length >= 2 && awardedBids > 0, icon: Workflow },
            { label: 'Template + Evidence', done: publishedTemplates > 0 && evidenceProvenanceEvents.length > 0, icon: FileCheck2 },
            { label: 'API + Enterprise', done: activeApiClients > 0 && configuredSsoProviders > 0 && enabledEnterprisePolicies > 0, icon: Lock },
            { label: 'Integrations + Mobile', done: failedWebhooks === 0 && activeMobile > 0, icon: Smartphone },
            { label: 'Quality Gates', done: pendingGates === 0 && runningQa === 0, icon: ShieldCheck },
          ].map((item) => {
            const Icon = item.icon;
            return (
              <div
                key={item.label}
                className={`rounded-lg border px-3 py-2 flex items-center gap-2 ${
                  item.done
                    ? 'border-emerald-200 dark:border-emerald-800/40 bg-emerald-50 dark:bg-emerald-900/20'
                    : 'border-amber-200 dark:border-amber-800/40 bg-amber-50 dark:bg-amber-900/20'
                }`}
              >
                <Icon className={`w-4 h-4 ${item.done ? 'text-emerald-600 dark:text-emerald-300' : 'text-amber-600 dark:text-amber-300'}`} />
                <div className="min-w-0">
                  <p className="text-[11px] font-semibold text-slate-700 dark:text-slate-200">{item.label}</p>
                  <p className="text-[10px] text-slate-500 dark:text-slate-400">{item.done ? 'ready' : 'needs work'}</p>
                </div>
                {item.done ? (
                  <CheckCircle2 className="w-4 h-4 text-emerald-500 ml-auto" />
                ) : (
                  <AlertTriangle className="w-4 h-4 text-amber-500 ml-auto" />
                )}
              </div>
            );
          })}
        </div>
      </section>
      ) : null}
      </div>
    </div>
  );
}
